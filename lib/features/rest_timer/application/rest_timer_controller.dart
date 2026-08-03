import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/notifications/local_notifications_service.dart';
import 'package:lifting_tracker_app/features/rest_timer/data/rest_timer_storage.dart';
import 'package:lifting_tracker_app/features/rest_timer/domain/rest_timer_state.dart';

final restTimerStorageProvider = Provider<RestTimerStorage>((ref) {
  return RestTimerStorage();
});

final localNotificationsServiceProvider = Provider<LocalNotificationsService>((
  ref,
) {
  return LocalNotificationsService();
});

final restTimerProvider =
    AsyncNotifierProvider<RestTimerController, RestTimerState>(
      RestTimerController.new,
    );

enum RestTimerNotificationResult {
  scheduled,
  scheduledInexactly,
  permissionDenied,
  unsupported,
  failed,
}

class RestTimerController extends AsyncNotifier<RestTimerState> {
  Timer? _ticker;
  late RestTimerStorage _storage;
  late LocalNotificationsService _notifications;

  LocalNotificationPermissionResult? _notificationPermissionResult;

  @override
  Future<RestTimerState> build() async {
    _storage = ref.watch(restTimerStorageProvider);
    _notifications = ref.watch(localNotificationsServiceProvider);

    ref.onDispose(_cancelTicker);

    final storedTimer = await _storage.load();

    if (storedTimer == null) {
      return const RestTimerState.idle();
    }

    final restoredState = RestTimerState.restored(
      configuredDuration: storedTimer.configuredDuration,
      progressDuration: storedTimer.progressDuration,
      endsAt: storedTimer.endsAt,
      now: DateTime.now(),
    );

    if (!restoredState.isRunning) {
      await _storage.clear();
      return restoredState;
    }

    _startTicker();
    return restoredState;
  }

  Future<RestTimerNotificationResult> start(Duration duration) async {
    if (!state.hasValue) {
      throw StateError('Rest timer has not finished initializing.');
    }

    if (duration <= Duration.zero) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Rest timer duration must be positive.',
      );
    }

    final permissionResult = await _tryGetNotificationPermissionResult();

    final runningState = RestTimerState.running(
      duration: duration,
      now: DateTime.now(),
    );

    await _storage.save(
      configuredDuration: runningState.configuredDuration,
      progressDuration: runningState.progressDuration,
      endsAt: runningState.endsAt!,
    );

    state = AsyncData(runningState);
    _startTicker();

    return _scheduleNotification(
      permissionResult: permissionResult,
      endsAt: runningState.endsAt!,
    );
  }

  Future<void> stop() async {
    if (!state.hasValue) return;

    final currentState = state.requireValue;

    if (!currentState.isRunning) return;

    _cancelTicker();

    try {
      await Future.wait([_storage.clear(), _cancelNotificationSafely()]);
    } finally {
      final isSameTimer =
          state.hasValue && state.requireValue.endsAt == currentState.endsAt;

      if (isSameTimer) {
        state = AsyncData(currentState.stop());
      }
    }
  }

  Future<RestTimerNotificationResult?> adjustTime({
    required Duration by,
  }) async {
    if (!state.hasValue) {
      throw StateError('Rest timer has not finished initializing.');
    }

    if (by == Duration.zero) {
      throw ArgumentError.value(by, 'by', 'Timer adjustment must not be zero.');
    }

    final currentState = state.requireValue;

    if (!currentState.isRunning) return null;

    final previewState = currentState.adjust(by: by, now: DateTime.now());

    if (!previewState.isRunning) {
      await stop();
      return null;
    }

    final permissionResult = await _tryGetNotificationPermissionResult();

    if (!state.hasValue || !state.requireValue.isRunning) {
      return null;
    }

    final adjustedState = state.requireValue.adjust(
      by: by,
      now: DateTime.now(),
    );

    if (!adjustedState.isRunning) {
      await stop();
      return null;
    }

    await _storage.save(
      configuredDuration: adjustedState.configuredDuration,
      progressDuration: adjustedState.progressDuration,
      endsAt: adjustedState.endsAt!,
    );

    state = AsyncData(adjustedState);
    _startTicker();

    return _scheduleNotification(
      permissionResult: permissionResult,
      endsAt: adjustedState.endsAt!,
    );
  }

  Future<RestTimerNotificationResult> _scheduleNotification({
    required LocalNotificationPermissionResult? permissionResult,
    required DateTime endsAt,
  }) async {
    if (permissionResult == null) {
      return RestTimerNotificationResult.failed;
    }

    try {
      switch (permissionResult) {
        case LocalNotificationPermissionsGranted():
          await _notifications.scheduleRestTimer(
            endsAt: endsAt,
            useExactAlarm: true,
          );
          return RestTimerNotificationResult.scheduled;

        case LocalExactAlarmsDenied():
          await _notifications.scheduleRestTimer(
            endsAt: endsAt,
            useExactAlarm: false,
          );
          return RestTimerNotificationResult.scheduledInexactly;

        case LocalNotificationsDenied():
          return RestTimerNotificationResult.permissionDenied;

        case LocalNotificationsUnsupported():
          return RestTimerNotificationResult.unsupported;
      }
    } catch (error, stackTrace) {
      _reportNotificationError(
        error,
        stackTrace,
        context: 'while scheduling the rest timer notification',
      );
      return RestTimerNotificationResult.failed;
    }
  }

  Future<LocalNotificationPermissionResult?>
  _tryGetNotificationPermissionResult() async {
    final cachedResult = _notificationPermissionResult;

    if (cachedResult != null) {
      return cachedResult;
    }

    try {
      final permissionResult = await _notifications.requestPermissions();

      _notificationPermissionResult = permissionResult;

      return permissionResult;
    } catch (error, stackTrace) {
      _reportNotificationError(
        error,
        stackTrace,
        context: 'while requesting notification permissions',
      );
      return null;
    }
  }

  Future<void> _cancelNotificationSafely() async {
    try {
      await _notifications.cancelRestTimer();
    } catch (error, stackTrace) {
      _reportNotificationError(
        error,
        stackTrace,
        context: 'while cancelling the rest timer notification',
      );
    }
  }

  void _startTicker() {
    _ticker?.cancel();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_refreshRemaining());
    });
  }

  Future<void> _refreshRemaining() async {
    if (!state.hasValue) return;

    final currentState = state.requireValue;

    if (!currentState.isRunning) return;

    final updatedState = currentState.recalculate(DateTime.now());

    if (updatedState.isRunning) {
      state = AsyncData(updatedState);
      return;
    }

    _cancelTicker();

    try {
      await _storage.clear();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'rest timer',
          context: ErrorDescription('while clearing an expired rest timer'),
        ),
      );
    }

    if (!state.hasValue || state.requireValue.endsAt != currentState.endsAt) {
      return;
    }

    state = AsyncData(updatedState);
  }

  void _cancelTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _reportNotificationError(
    Object error,
    StackTrace stackTrace, {
    required String context,
  }) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'rest timer notifications',
        context: ErrorDescription(context),
      ),
    );
  }
}
