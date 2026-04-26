import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/providers/persisted/week_progress.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';

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

    Widget buildDayBadge(String calendarDay, bool didAttend, bool isToday) {
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
        height: 44,
        width: 44,
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          const Center(child: Text('An error has occured! Try again.')),
      data: (weeklyWorkoutProgress) {
        final progress =
            ref
                .read(weeklyWorkoutProgressProvider.notifier)
                .returnCurrentProgress() /
            weeklyWorkoutProgress.target;

        return Column(
          children: [
            SizedBox(
              height: 64,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final weekday in weekdays)
                    Builder(
                      builder: (context) {
                        final isToday = DateUtils.isSameDay(weekday, today);
                        final didUserAttendGym = weeklyWorkoutProgress
                            .weeklyGymAttendance[weekday.weekday - 1];
                        final weekDayLabel = dayFormatter.format(weekday);
                        final calendarDayLabel = weekday.day.toString();

                        return Column(
                          children: [
                            Text(
                              weekDayLabel,
                              style: Theme.of(context).textTheme.bodySmall!
                                  .copyWith(color: AppColors.primary),
                            ),
                            const Spacer(),
                            buildDayBadge(
                              calendarDayLabel,
                              didUserAttendGym,
                              isToday,
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
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
                        '${ref.read(weeklyWorkoutProgressProvider.notifier).returnCurrentProgress()}/${weeklyWorkoutProgress.target}',
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0, end: progress),
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
                  const SizedBox(height: 8),
                  Text(
                    'One more workout to reach your goal',
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
