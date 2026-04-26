import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/widgets/homescreen/last_session_section.dart';
import 'package:lifting_tracker_app/widgets/homescreen/next_in_cycle_section.dart';
import 'package:lifting_tracker_app/widgets/homescreen/progress_spotlight.dart';
import 'package:lifting_tracker_app/widgets/homescreen/start_session.dart';
import 'package:lifting_tracker_app/widgets/homescreen/week_progress.dart';

class Home extends ConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(left: 18, right: 18, bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WeekProgress(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: LastSessionSection()),
                const SizedBox(width: 16),
                Expanded(child: NextInCycleSection()),
              ],
            ),
            const SizedBox(height: 16),
            ProgressSpotlight(),
            const SizedBox(height: 18), //optic ilussion,
            StartSession(),
          ],
        ),
      ),
    );
  }
}
