import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/homescreen/last_session_section.dart';
import 'package:lifting_tracker_app/widgets/homescreen/next_in_cycle_section.dart';
import 'package:lifting_tracker_app/widgets/homescreen/progress_spotlight.dart';
import 'package:lifting_tracker_app/widgets/homescreen/start_session.dart';
import 'package:lifting_tracker_app/widgets/homescreen/week_progress.dart';

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
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: AppColors.accentLightBlue,
              ),
            ),
            const SizedBox(height: 2),
            Text(weekdayLabel, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Image.asset('assets/fire.png', height: 18, width: 18),
                const SizedBox(width: 4),
                Text('7', style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: AppColors.bgMain,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(onPressed: () {}, icon: Icon(Icons.home), iconSize: 28),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.settings),
              iconSize: 28,
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WeekProgress(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: LastSessionSection()),
                  const SizedBox(width: 6),
                  Expanded(child: NextInCycleSection()),
                ],
              ),
              const SizedBox(height: 6),
              ProgressSpotlight(),
              const SizedBox(height: 7), //optic ilussion,
              StartSession(),
            ],
          ),
        ),
      ),
    );
  }
}
