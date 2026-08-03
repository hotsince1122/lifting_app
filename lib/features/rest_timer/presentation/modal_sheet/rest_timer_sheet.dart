import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/modal/modal_scaffold.dart';
import 'package:lifting_tracker_app/features/rest_timer/application/rest_timer_controller.dart';
import 'package:lifting_tracker_app/features/rest_timer/presentation/widgets/rest_timer_adjustment_button.dart';
import 'package:lifting_tracker_app/features/rest_timer/presentation/widgets/rest_timer_dial.dart';
import 'package:lifting_tracker_app/features/rest_timer/presentation/widgets/rest_timer_preset.dart';

class RestTimerSheet extends ConsumerStatefulWidget {
  const RestTimerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black12,
      builder: (_) => const RestTimerSheet(),
    );
  }

  @override
  ConsumerState<RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends ConsumerState<RestTimerSheet> {
  static const _presets = [
    (label: '1:30', duration: Duration(seconds: 90)),
    (label: '2:00', duration: Duration(minutes: 2)),
    (label: '3:00', duration: Duration(minutes: 3)),
  ];

  Duration? _selectedDuration;
  Duration? _selectedPresetDuration;
  bool _didInitializeDuration = false;
  bool _didShowNotificationWarning = false;
  bool _isBusy = false;

  void _initializeDuration(Duration configuredDuration) {
    if (_didInitializeDuration) return;

    _selectedDuration = configuredDuration;
    _selectedPresetDuration =
        _presets.any((preset) => preset.duration == configuredDuration)
        ? configuredDuration
        : null;
    _didInitializeDuration = true;
  }

  void _adjustConfiguredDuration(Duration by) {
    final currentDuration = _selectedDuration;
    if (currentDuration == null) return;

    final adjustedDuration = currentDuration + by;
    const minimumDuration = Duration(seconds: 15);

    if (adjustedDuration < minimumDuration) return;

    setState(() {
      _selectedDuration = adjustedDuration;
      _selectedPresetDuration = null;
    });
  }

  Future<void> _runTimerAction({
    required Future<void> Function() action,
    required String errorMessage,
  }) async {
    if (_isBusy) return;

    setState(() {
      _isBusy = true;
    });

    try {
      await action();
    } catch (_) {
      if (!mounted) return;

      SnackBarError.show(context, errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _startTimer() async {
    final selectedDuration = _selectedDuration;

    if (selectedDuration == null) return;

    await _runTimerAction(
      action: () async {
        final notificationResult = await ref
            .read(restTimerProvider.notifier)
            .start(selectedDuration);

        if (mounted) {
          _showNotificationFeedback(notificationResult);
        }
      },
      errorMessage: 'Could not start the rest timer.',
    );
  }

  Future<void> _adjustTimer(Duration by) {
    return _runTimerAction(
      action: () async {
        final notificationResult = await ref
            .read(restTimerProvider.notifier)
            .adjustTime(by: by);

        if (mounted && notificationResult != null) {
          _showNotificationFeedback(notificationResult);
        }
      },
      errorMessage: 'Could not adjust the rest timer.',
    );
  }

  Future<void> _stopTimer() {
    return _runTimerAction(
      action: () async {
        await ref.read(restTimerProvider.notifier).stop();
      },
      errorMessage: 'Could not stop the rest timer.',
    );
  }

  void _showNotificationFeedback(RestTimerNotificationResult result) {
    if (_didShowNotificationWarning) return;

    final message = switch (result) {
      RestTimerNotificationResult.scheduled => null,
      RestTimerNotificationResult.scheduledInexactly =>
        'Exact alarms are disabled. The timer notification may be delayed.',
      RestTimerNotificationResult.permissionDenied =>
        'Timer is running, but notifications are disabled.',
      RestTimerNotificationResult.unsupported =>
        'Timer is running, but notifications are not supported on this device.',
      RestTimerNotificationResult.failed =>
        'Timer is running, but its notification could not be scheduled.',
    };

    if (message == null) return;

    _didShowNotificationWarning = true;
    SnackBarError.show(context, message);
  }

  Widget _buildTimerControls(bool isRunning) {
    final selectedDuration = _selectedDuration;
    final canDecreaseIdle =
        selectedDuration != null &&
        selectedDuration > const Duration(seconds: 15);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RestTimerAdjustmentButton(
          label: '-15',
          onPressed: _isBusy || (!isRunning && !canDecreaseIdle)
              ? null
              : () async {
                  if (isRunning) {
                    await _adjustTimer(const Duration(seconds: -15));
                  } else {
                    _adjustConfiguredDuration(const Duration(seconds: -15));
                  }
                },
        ),
        const SizedBox(width: AppSpacing.s20),
        _RestTimerToggleButton(
          isRunning: isRunning,
          onPressed: _isBusy
              ? null
              : () async {
                  if (isRunning) {
                    await _stopTimer();
                  } else {
                    await _startTimer();
                  }
                },
        ),
        const SizedBox(width: AppSpacing.s20),
        RestTimerAdjustmentButton(
          label: '+15',
          onPressed: _isBusy
              ? null
              : () async {
                  if (isRunning) {
                    await _adjustTimer(const Duration(seconds: 15));
                  } else {
                    _adjustConfiguredDuration(const Duration(seconds: 15));
                  }
                },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final timerAsync = ref.watch(restTimerProvider);

    return ModalScaffold(
      heightFactor: 0.72,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        child: Column(
          children: [
            SizedBox(
              height: AppSpacing.s48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Rest timer',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      iconSize: 18,
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: timerAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: Text(
                    'Could not load the rest timer.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                data: (timerState) {
                  _initializeDuration(timerState.configuredDuration);

                  final displayedDuration = timerState.isRunning
                      ? timerState.remaining
                      : _selectedDuration!;

                  return Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: RestTimerDial(
                            state: timerState,
                            displayedDuration: displayedDuration,
                          ),
                        ),
                      ),
                      IgnorePointer(
                        ignoring: timerState.isRunning,
                        child: AnimatedOpacity(
                          duration: Duration(milliseconds: 220),
                          opacity: !timerState.isRunning ? 1.0 : 0.0,
                          child: Column(
                            children: [
                              Text(
                                'Choose rest time',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AppSpacing.s12),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: AppSpacing.s8,
                                children: [
                                  for (final preset in _presets)
                                    RestTimerPreset(
                                      label: preset.label,
                                      isSelected:
                                          _selectedPresetDuration ==
                                          preset.duration,
                                      onPressed: () {
                                        if (_isBusy) return;

                                        setState(() {
                                          _selectedDuration = preset.duration;
                                          _selectedPresetDuration =
                                              preset.duration;
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s32),
                      _buildTimerControls(timerState.isRunning),
                      const SizedBox(height: AppSpacing.s32),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestTimerToggleButton extends StatelessWidget {
  const _RestTimerToggleButton({
    required this.isRunning,
    required this.onPressed,
  });

  final bool isRunning;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 76,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          backgroundColor: isRunning ? AppColors.surface : AppColors.secondary,
          foregroundColor: isRunning
              ? AppColors.onSurface
              : AppColors.background,
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Icon(
            isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
            key: ValueKey(isRunning),
            size: 48,
          ),
        ),
      ),
    );
  }
}
