class RestTimerState {
  const RestTimerState._({
    required this.configuredDuration,
    required this.progressDuration,
    required this.endsAt,
    required this.remaining,
  });

  double get remainingFraction {
    if (!isRunning) return 1;

    final progressMicroseconds = progressDuration.inMicroseconds;
    if (progressMicroseconds <= 0) return 0;

    return (remaining.inMicroseconds / progressMicroseconds)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  const RestTimerState.idle({
    this.configuredDuration = const Duration(seconds: 90),
  }) : endsAt = null,
       progressDuration = configuredDuration,
       remaining = Duration.zero;

  factory RestTimerState.running({
    required Duration duration,
    required DateTime now,
  }) {
    _validateDuration(duration);

    return RestTimerState._(
      configuredDuration: duration,
      progressDuration: duration,
      endsAt: now.add(duration),
      remaining: duration,
    );
  }

  factory RestTimerState.restored({
    required Duration configuredDuration,
    required Duration progressDuration,
    required DateTime endsAt,
    required DateTime now,
  }) {
    _validateDuration(configuredDuration);
    _validateDuration(progressDuration);

    final remaining = endsAt.difference(now);

    if (remaining <= Duration.zero) {
      return RestTimerState.idle(configuredDuration: configuredDuration);
    }

    return RestTimerState._(
      configuredDuration: configuredDuration,
      progressDuration: progressDuration,
      endsAt: endsAt,
      remaining: remaining,
    );
  }

  final Duration configuredDuration;
  final Duration progressDuration;
  final DateTime? endsAt;
  final Duration remaining;

  bool get isRunning => endsAt != null;

  RestTimerState recalculate(DateTime now) {
    final currentEndsAt = endsAt;

    if (currentEndsAt == null) return this;

    final updatedRemaining = currentEndsAt.difference(now);

    if (updatedRemaining <= Duration.zero) {
      return RestTimerState.idle(configuredDuration: configuredDuration);
    }

    return RestTimerState._(
      configuredDuration: configuredDuration,
      progressDuration: progressDuration,
      endsAt: currentEndsAt,
      remaining: updatedRemaining,
    );
  }

  RestTimerState adjust({required Duration by, required DateTime now}) {
    if (by == Duration.zero) {
      throw ArgumentError.value(by, 'by', 'Timer adjustment must not be zero.');
    }

    final currentEndsAt = endsAt;

    if (currentEndsAt == null) {
      throw StateError('Cannot adjust an idle rest timer.');
    }

    final wasExpired = !currentEndsAt.isAfter(now);
    final adjustmentBase = wasExpired ? now : currentEndsAt;
    final adjustedEndsAt = adjustmentBase.add(by);

    if (!adjustedEndsAt.isAfter(now)) {
      return stop();
    }

    final adjustedRemaining = adjustedEndsAt.difference(now);
    final adjustedProgressDuration =
        wasExpired || adjustedRemaining > progressDuration
        ? adjustedRemaining
        : progressDuration;

    return RestTimerState._(
      configuredDuration: configuredDuration,
      progressDuration: adjustedProgressDuration,
      endsAt: adjustedEndsAt,
      remaining: adjustedRemaining,
    );
  }

  RestTimerState stop() {
    return RestTimerState.idle(configuredDuration: configuredDuration);
  }

  static void _validateDuration(Duration duration) {
    if (duration <= Duration.zero) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Rest timer duration must be positive.',
      );
    }
  }
}
