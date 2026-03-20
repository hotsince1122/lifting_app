import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/providers/persisted/week_progress.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';

class WeekProgress extends ConsumerWidget {
  const WeekProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final dayFormatter = DateFormat('EEE', 'en_US');

    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final weekdays = List.generate(
      7,
      (index) => startOfWeek.add(Duration(days: index)),
    );

    final weeklyWorkoutProgressAsync = ref.watch(weeklyWorkoutProgressProvider);

    Widget wrapWithContainerIfToday(Widget child, bool isToday) {
      return isToday
          ? Container(
              height: 68,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: Gradients.of(AppGradients.lightOne),
                borderRadius: BorderRadius.circular(24),
              ),
              child: child,
            )
          : child;
    }

    Widget wrapWithContainerIfAttendedGym(
      Widget child,
      bool didAttend,
      bool isToday,
    ) {
      return didAttend && !isToday
          ? Container(
              height: 32,
              width: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: Gradients.of(AppGradients.lightOne),
                shape: BoxShape.circle,
              ),
              child: child,
            )
          : child;
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final weekday in weekdays)
                  Builder(
                    builder: (context) {
                      final isToday = DateUtils.isSameDay(weekday, today);
                      final label = dayFormatter.format(weekday);

                      return wrapWithContainerIfToday(
                        SizedBox(
                          height: 68,
                          width: 48,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(
                                label,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              wrapWithContainerIfAttendedGym(
                                Text(
                                  weekday.day.toString(),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                weeklyWorkoutProgress
                                    .weeklyGymAttendance[weekday.weekday - 1],
                                isToday,
                              ),
                            ],
                          ),
                        ),
                        isToday,
                      );
                    },
                  ),
              ],
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
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${ref.read(weeklyWorkoutProgressProvider.notifier).returnCurrentProgress()}/${weeklyWorkoutProgress.target}',
                        style: Theme.of(context).textTheme.titleMedium,
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
                        backgroundColor: AppColors.darkCardsMain,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        minHeight: 8,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'One more workout to reach your goal',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: AppColors.accentLightBlue,
                    ),
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
