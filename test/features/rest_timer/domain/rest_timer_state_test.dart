import 'package:flutter_test/flutter_test.dart';
import 'package:lifting_tracker_app/features/rest_timer/domain/rest_timer_state.dart';

void main() {
  group('RestTimerState', () {
    final now = DateTime.utc(2026, 8, 4, 12);

    test('starts with the full configured duration', () {
      final state = RestTimerState.running(
        duration: const Duration(seconds: 90),
        now: now,
      );

      expect(state.isRunning, isTrue);
      expect(state.configuredDuration, const Duration(seconds: 90));
      expect(state.progressDuration, const Duration(seconds: 90));
      expect(state.remaining, const Duration(seconds: 90));
      expect(state.endsAt, now.add(const Duration(seconds: 90)));
      expect(state.remainingFraction, 1);
    });

    test('recalculates remaining time from the absolute end time', () {
      final state = RestTimerState.running(
        duration: const Duration(seconds: 90),
        now: now,
      );

      final updatedState = state.recalculate(
        now.add(const Duration(seconds: 30)),
      );

      expect(updatedState.remaining, const Duration(seconds: 60));
      expect(updatedState.remainingFraction, closeTo(2 / 3, 0.000001));
    });

    test('subtracting time updates the dial by the correct fraction', () {
      final state = RestTimerState.running(
        duration: const Duration(seconds: 90),
        now: now,
      );

      final adjustedState = state.adjust(
        by: const Duration(seconds: -30),
        now: now,
      );

      expect(adjustedState.remaining, const Duration(seconds: 60));
      expect(adjustedState.progressDuration, const Duration(seconds: 90));
      expect(adjustedState.remainingFraction, closeTo(2 / 3, 0.000001));
    });

    test('adding beyond the original duration expands the dial range', () {
      final state = RestTimerState.running(
        duration: const Duration(seconds: 90),
        now: now,
      );

      final adjustedState = state.adjust(
        by: const Duration(seconds: 30),
        now: now,
      );

      expect(adjustedState.remaining, const Duration(seconds: 120));
      expect(adjustedState.progressDuration, const Duration(seconds: 120));
      expect(adjustedState.remainingFraction, 1);
    });

    test('subtracting all remaining time stops the timer', () {
      final state = RestTimerState.running(
        duration: const Duration(seconds: 90),
        now: now,
      );

      final adjustedState = state.adjust(
        by: const Duration(seconds: -90),
        now: now,
      );

      expect(adjustedState.isRunning, isFalse);
      expect(adjustedState.configuredDuration, const Duration(seconds: 90));
    });

    test('restores progress using the persisted progress duration', () {
      final state = RestTimerState.restored(
        configuredDuration: const Duration(seconds: 90),
        progressDuration: const Duration(seconds: 120),
        endsAt: now.add(const Duration(seconds: 90)),
        now: now,
      );

      expect(state.remaining, const Duration(seconds: 90));
      expect(state.remainingFraction, closeTo(0.75, 0.000001));
    });

    test('restores an expired timer as idle', () {
      final state = RestTimerState.restored(
        configuredDuration: const Duration(seconds: 90),
        progressDuration: const Duration(seconds: 90),
        endsAt: now.subtract(const Duration(seconds: 1)),
        now: now,
      );

      expect(state.isRunning, isFalse);
      expect(state.configuredDuration, const Duration(seconds: 90));
    });
  });
}
