import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

sealed class LocalNotificationPermissionResult {
  const LocalNotificationPermissionResult();
}

final class LocalNotificationPermissionsGranted
    extends LocalNotificationPermissionResult {
  const LocalNotificationPermissionsGranted();
}

final class LocalNotificationsDenied extends LocalNotificationPermissionResult {
  const LocalNotificationsDenied();
}

final class LocalExactAlarmsDenied extends LocalNotificationPermissionResult {
  const LocalExactAlarmsDenied();
}

final class LocalNotificationsUnsupported
    extends LocalNotificationPermissionResult {
  const LocalNotificationsUnsupported();
}

class LocalNotificationsService {
  static const int _restTimerNotificationId = 1001;

  static const _channelId = 'rest_timer';
  static const _channelName = 'Rest timer';
  static const _channelDescription = 'Notifies when your rest timer finishes.';

  static const NotificationDetails _restTimerNotificationDetails =
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          playSound: true,
          enableVibration: true,
          channelShowBadge: false,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentList: true,
          presentSound: true,
          presentBadge: false,
          interruptionLevel: InterruptionLevel.active,
          threadIdentifier: _channelId,
        ),
      );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get _isSupportedPlatform {
    if (kIsWeb) return false;

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() async {
    if (_isInitialized || !_isSupportedPlatform) return;

    await _configureLocalTimeZone();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_rest_timer'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    final didInitialize = await _plugin.initialize(
      settings: initializationSettings,
    );

    if (didInitialize != true) {
      throw StateError('Could not initialize local notifications.');
    }

    _isInitialized = true;
  }

  Future<LocalNotificationPermissionResult> requestPermissions() async {
    if (!_isSupportedPlatform) {
      return const LocalNotificationsUnsupported();
    }

    await initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      return _requestAndroidPermissions();
    }

    return _requestIosPermissions();
  }

  Future<LocalNotificationPermissionResult> _requestAndroidPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final notificationsGranted =
        await androidPlugin?.requestNotificationsPermission() ?? false;

    if (!notificationsGranted) {
      return const LocalNotificationsDenied();
    }

    var exactAlarmsGranted =
        await androidPlugin?.canScheduleExactNotifications() ?? false;

    if (!exactAlarmsGranted) {
      exactAlarmsGranted =
          await androidPlugin?.requestExactAlarmsPermission() ?? false;
    }

    if (!exactAlarmsGranted) {
      return const LocalExactAlarmsDenied();
    }

    return const LocalNotificationPermissionsGranted();
  }

  Future<LocalNotificationPermissionResult> _requestIosPermissions() async {
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    final notificationsGranted =
        await iosPlugin?.requestPermissions(
          alert: true,
          badge: false,
          sound: true,
        ) ??
        false;

    return notificationsGranted
        ? const LocalNotificationPermissionsGranted()
        : const LocalNotificationsDenied();
  }

  Future<void> scheduleRestTimer({
    required DateTime endsAt,
    required bool useExactAlarm,
  }) async {
    if (!_isSupportedPlatform) return;

    if (!endsAt.isAfter(DateTime.now())) {
      throw ArgumentError.value(
        endsAt,
        'endsAt',
        'The rest timer end must be in the future',
      );
    }

    await initialize();

    await _plugin.cancel(id: _restTimerNotificationId);

    await _plugin.zonedSchedule(
      id: _restTimerNotificationId,
      title: 'Rest timer finished',
      body: 'Time for your next set.',
      scheduledDate: tz.TZDateTime.from(endsAt, tz.local),
      notificationDetails: _restTimerNotificationDetails,
      androidScheduleMode: useExactAlarm
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'rest_timer',
    );
  }

  Future<void> cancelRestTimer() async {
    if (!_isSupportedPlatform) return;

    await initialize();
    await _plugin.cancel(id: _restTimerNotificationId);
  }

  Future<void> _configureLocalTimeZone() async {
    tz_data.initializeTimeZones();

    try {
      final localTimeZone = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(localTimeZone.identifier);

      tz.setLocalLocation(location);
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }
}
