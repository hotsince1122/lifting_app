import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/presentation/next_in_cycle.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/widgets/gradient_cards.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class NextInCycleSection extends ConsumerWidget {
  const NextInCycleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AspectRatio(
      aspectRatio: 1.2,
      child: GradientCard(
        gradientVariant: Gradients.of(AppGradients.darkThree),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.navigate_next_rounded,
                  size: 22,
                  color: AppColors.accentLightBlue,
                ),
                const SizedBox(width: 4),
                Text(
                  'Next in cycle',
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 18,),
            _NextSessionInfoAsync(),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _NextSessionInfoAsync extends ConsumerWidget {
  const _NextSessionInfoAsync();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextInCycleAsync = ref.watch(nextInCycleProvider);

    return nextInCycleAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          const Center(child: Text('An error has occured! Try again.')),
      data: (nextInCycle) {
        final String nrOfExercisesLabel =
            '${nextInCycle.nrOfExercises} exercise${nextInCycle.nrOfExercises == 1 ? 's' : ''} planned.';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nextInCycle.workoutName,
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              nextInCycle.muscleGroups == null
                  ? 'No exercises added yet.'
                  : nextInCycle.muscleGroups!,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.accentLightBlue),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                PhosphorIcon(PhosphorIcons.barbell(), size: 14, color: AppColors.accentLightBlue,),
                const SizedBox(width: 4,),
                Text(
                  nextInCycle.muscleGroups == null
                      ? 'Start now and build as you go.'
                      : nrOfExercisesLabel,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppColors.accentLightBlue),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
