import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/features/rest_timer/application/rest_timer_controller.dart';
import 'package:lifting_tracker_app/features/rest_timer/presentation/modal_sheet/rest_timer_sheet.dart';
import 'package:lifting_tracker_app/features/rest_timer/presentation/view_data/rest_timer_duration_formatter.dart';

class RestTimerAppBarControl extends ConsumerWidget {
  const RestTimerAppBarControl({
    required this.height,
    required this.iconSize,
    super.key,
  });

  final double height;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerAsync = ref.watch(restTimerProvider);
    final timerState = timerAsync.hasValue ? timerAsync.requireValue : null;
    final isRunning = timerState?.isRunning ?? false;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            await RestTimerSheet.show(context);
          },
          borderRadius: BorderRadius.circular(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: 48, minHeight: height),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isRunning ? 12 : 0),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: isRunning
                      ? Text(
                          formatRestTimerDuration(timerState!.remaining),
                          key: const ValueKey('running-rest-timer'),
                          maxLines: 1,
                          softWrap: false,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        )
                      : Icon(
                          Icons.timer_sharp,
                          key: const ValueKey('idle-rest-timer'),
                          fontWeight: FontWeight.w600,
                          size: iconSize,
                          color: AppColors.onSurface,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
