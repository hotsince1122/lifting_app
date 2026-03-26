import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/presentation/last_workout_completed.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/widgets/gradient_cards.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class LastSessionSection extends StatelessWidget {
  const LastSessionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.15,
      child: GradientCard(
        gradientVariant: AppGradients.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PhosphorIcon(PhosphorIcons.clockCounterClockwise(), size: 20, color: AppColors.primary,),
                const SizedBox(width: 6,),
                Text(
                  'Last session',
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 22,),
            _LastSessionInfoAsync(),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _LastSessionInfoAsync extends ConsumerWidget {
  const _LastSessionInfoAsync();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastWorkoutCompletedAsync = ref.watch(lastWorkoutCompletedProvider);


    return lastWorkoutCompletedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('An error has occured.')),
      data: (lastWorkoutCompleted) {
        if (lastWorkoutCompleted == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No sessions yet.',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your latest workout will appear here.',
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
              ),
            ],
          );
        }
        return SizedBox();
      },
    );
  }
}
