import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/features/progress/application/weekly_workout_progress_controller.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/features/progress/presentation/copy/weekly_progress_messages.dart';

class WeekProgress extends ConsumerWidget {
  const WeekProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(weeklyWorkoutProgressProvider.notifier).syncCurrentWeek();
    });

    final now = DateTime.now();
    final dayFormatter = DateFormat('EEE', 'en_US');

    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final weekdays = List.generate(
      7,
      (index) => startOfWeek.add(Duration(days: index)),
    );

    final weeklyWorkoutProgressAsync = ref.watch(weeklyWorkoutProgressProvider);

    const calendarHeight = 64.0;
    const minBadgeSize = 32.0;
    const maxBadgeSize = 44.0;

    Widget buildDayBadge(
      String calendarDay,
      bool didAttend,
      bool isToday,
      double size,
    ) {
      final backgroundColor = isToday
          ? AppColors.primary
          : didAttend
          ? AppColors.surface
          : AppColors.background;

      final textColor = isToday
          ? AppColors.background
          : didAttend
          ? null
          : AppColors.primary;

      final borderColor = isToday ? AppColors.surface : Colors.transparent;

      return Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Padding(
          padding: EdgeInsets.all(2),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              calendarDay,
              style: Theme.of(
                context,
              ).textTheme.titleSmall!.copyWith(color: textColor),
            ),
          ),
        ),
      );
    }

    return weeklyWorkoutProgressAsync.when(
      loading: () => const SizedBox(
        height: calendarHeight,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) =>
          const Center(child: Text('An error has occured! Try again.')),
      data: (weeklyWorkoutProgress) {
        final currentProgress = ref
            .read(weeklyWorkoutProgressProvider.notifier)
            .returnCurrentProgress();

        final progressBar = (currentProgress / weeklyWorkoutProgress.target)
            .clamp(0.0, 1.0)
            .toDouble();

        final weeklyProgressMessage = selectProgressMessage(
          currentProgress: currentProgress,
          target: weeklyWorkoutProgress.target,
          weekStart: startOfWeek,
        );

        return Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final cellWidth = constraints.maxWidth / weekdays.length;
                final badgeSize = cellWidth
                    .clamp(minBadgeSize, maxBadgeSize)
                    .toDouble();

                return SizedBox(
                  height: 64,
                  child: Row(
                    children: [
                      for (final weekday in weekdays)
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final isToday = DateUtils.isSameDay(
                                weekday,
                                today,
                              );
                              final didUserAttendGym = weeklyWorkoutProgress
                                  .weeklyGymAttendance[weekday.weekday - 1];
                              final weekDayLabel = dayFormatter.format(weekday);
                              final calendarDayLabel = weekday.day.toString();

                              return Column(
                                children: [
                                  Text(
                                    weekDayLabel,
                                    maxLines: 1,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(color: AppColors.primary),
                                  ),
                                  const Spacer(),
                                  buildDayBadge(
                                    calendarDayLabel,
                                    didUserAttendGym,
                                    isToday,
                                    badgeSize,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.s12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Weekly goal',
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '$currentProgress/${weeklyWorkoutProgress.target}',
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: progressBar),
                    duration: Duration(milliseconds: 500),
                    builder: (context, progress, child) {
                      return LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.card,
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        minHeight: 6,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    weeklyProgressMessage,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall!.copyWith(color: AppColors.primary),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
