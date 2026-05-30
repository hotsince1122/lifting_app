import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/presentation/history_months.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/widgets/gradient_button.dart';
import 'package:lifting_tracker_app/widgets/gradient_cards.dart';
import 'package:lifting_tracker_app/widgets/history_screen/history_month_card.dart';
import 'package:lifting_tracker_app/widgets/session_launch_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class History extends ConsumerWidget {
  const History({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyMonthsAsync = ref.watch(historyMonthsProvider);

    return historyMonthsAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text('An error has occured! Try again.')),
      data: (historyMonthsData) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: historyMonthsData.isEmpty
              ? emptyState(context)
              : ListView.builder(
                  itemBuilder: (context, i) =>
                      HistoryMonthCard(historyMonthsData[i]),
                  itemCount: historyMonthsData.length,
                ),
        );
      },
    );
  }

  Widget emptyState(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 96),
          GradientCard(
            gradientVariant: AppGradients.card,
            padding: const EdgeInsets.all(28),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Icon(
                PhosphorIcons.barbell(),
                color: AppColors.onSurfaceMuted,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No workouts yet',
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Complete your first training session and it will appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              color: AppColors.primary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 36),

          SessionLaunchButton(
            buttonBuilder: (context, onPressed, child) {
              return GradientButton(
                isActive: false,
                onPressed: onPressed,
                gradientVariant: AppGradients.card,
                child: child,
              );
            },
            contentBuilder: (context, isActive, workoutName) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isActive ? 'Resume' : 'Start'} your first workout',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          isActive
                              ? 'Continue your active workout'
                              : '$workoutName day is next in your plan',
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(color: AppColors.onSurfaceMuted),
                        ),
                      ],
                    ),
                    const Spacer(),
                    CircleAvatar(
                      backgroundColor: AppColors.primaryTransparent,
                      child: Icon(Icons.arrow_forward_rounded),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
