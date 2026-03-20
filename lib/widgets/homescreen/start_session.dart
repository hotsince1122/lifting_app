import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/presentation/next_in_cycle.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/widgets/gradient_button.dart';

class StartSession extends StatelessWidget {
  const StartSession({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GradientButton(
        isActive: false,
        gradientVariant: Gradients.of(AppGradients.lightOne),
        onPressed: () {},
        buttonHight: 62,
        child: _SessionName(),
      ),
    );
  }
}

class _SessionName extends ConsumerWidget {
  const _SessionName();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextInCycleAsync = ref.watch(nextInCycleProvider);

    return nextInCycleAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('An error has occured!')),
      data: (nextInCycle) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow, size: 32, color: AppColors.bgMain),
            const SizedBox(width: 6),
            Text(
              'Start ',
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(color: AppColors.bgMain),
            ),
            Text(
              nextInCycle.workoutName,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: AppColors.bgMain,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        );
      },
    );
  }
}
