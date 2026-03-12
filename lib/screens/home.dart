import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/providers/persisted/week_progress.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';

class Home extends ConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();

    final String monthLabel = DateFormat('MMMM', 'en_US').format(now);
    final String weekdayLabel = DateFormat('EEEE', 'en_US').format(now);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              '$monthLabel ${now.day},',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 2),
            Text(weekdayLabel, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_WeekProgress()],
        ),
      ),
    );
  }
}

class _WeekProgress extends ConsumerWidget {
  const _WeekProgress();

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

    final workoutsProgressAsync = ref.watch(workoutsPerWeekProvider);

    return workoutsProgressAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          const Center(child: Text('An error has occured! Try again.')),
      data: (workoutsProgress) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final weekday in weekdays)
              Builder(
                builder: (context) {
                  final isToday = DateUtils.isSameDay(weekday, today);
                  final label = dayFormatter.format(weekday);

                  return Container(
                    height: isToday ? 72 : 64,
                    width: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isToday
                          ? AppColors.accentLightBlue
                          : AppColors.bgSecondary,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          weekday.day.toString(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
