import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/widgets/bottom_nav_bar.dart';
import 'package:lifting_tracker_app/widgets/gradient_cards.dart';
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              weekdayLabel,
              style: Theme.of(
                context,
              ).textTheme.headlineLarge!.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 6),
            child: GradientCard(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              gradientVariant: AppGradients.card,
              child: Row(
                children: [
                  Image.asset('assets/fire.png', height: 16, width: 16),
                  const SizedBox(width: 8),
                  Text('7', style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
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
      ),
    );
  }
}

