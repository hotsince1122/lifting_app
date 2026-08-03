String formatRestTimerDuration(Duration duration) {
  final totalSeconds = duration <= Duration.zero
      ? 0
      : (duration.inMilliseconds / Duration.millisecondsPerSecond).ceil();

  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds.remainder(60).toString().padLeft(2, '0');

  return '$minutes:$seconds';
}
