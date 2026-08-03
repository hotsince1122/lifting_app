import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StoredRestTimer {
  const StoredRestTimer({
    required this.configuredDuration,
    required this.progressDuration,
    required this.endsAt,
  });

  final Duration configuredDuration;
  final Duration progressDuration;
  final DateTime endsAt;
}

class RestTimerStorage {
  RestTimerStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _activeTimerKey = 'rest_timer.active.v1';

  final SharedPreferencesAsync _preferences;

  Future<void> save({
    required Duration configuredDuration,
    required Duration progressDuration,
    required DateTime endsAt,
  }) async {
    if (configuredDuration <= Duration.zero) {
      throw ArgumentError.value(
        configuredDuration,
        'configuredDuration',
        'Rest timer duration must be positive',
      );
    }

    if (progressDuration <= Duration.zero) {
      throw ArgumentError.value(
        progressDuration,
        'progressDuration',
        'Rest timer progress duration must be positive',
      );
    }

    final encodedTimer = jsonEncode({
      'configuredDurationMilliseconds': configuredDuration.inMilliseconds,
      'progressDurationMilliseconds': progressDuration.inMilliseconds,
      'endsAtMillisecondsSinceEpoch': endsAt.millisecondsSinceEpoch,
    });

    await _preferences.setString(_activeTimerKey, encodedTimer);
  }

  Future<StoredRestTimer?> load() async {
    final encodedTimer = await _preferences.getString(_activeTimerKey);

    if (encodedTimer == null) return null;

    try {
      final decodedTimer = jsonDecode(encodedTimer);

      if (decodedTimer is! Map<String, dynamic>) {
        throw const FormatException('Invalid rest timer data');
      }

      final configuredDurationMilliseconds =
          decodedTimer['configuredDurationMilliseconds'];
      final progressDurationMilliseconds =
          decodedTimer['progressDurationMilliseconds'];
      final endsAtMillisecondsSinceEpoch =
          decodedTimer['endsAtMillisecondsSinceEpoch'];

      if (configuredDurationMilliseconds is! int ||
          configuredDurationMilliseconds <= 0 ||
          progressDurationMilliseconds is! int ||
          progressDurationMilliseconds <= 0 ||
          endsAtMillisecondsSinceEpoch is! int) {
        throw const FormatException('Invalid rest timer values.');
      }

      final endsAt = DateTime.fromMillisecondsSinceEpoch(
        endsAtMillisecondsSinceEpoch,
      );

      return StoredRestTimer(
        configuredDuration: Duration(
          milliseconds: configuredDurationMilliseconds,
        ),
        progressDuration: Duration(milliseconds: progressDurationMilliseconds),
        endsAt: endsAt,
      );
    } on FormatException {
      await clear();
      return null;
    }
  }

  Future<void> clear() {
    return _preferences.remove(_activeTimerKey);
  }
}
