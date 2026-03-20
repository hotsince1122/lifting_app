import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/presentation/last_workout_completed.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/widgets/gradient_cards.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';

class LastSessionSection extends StatelessWidget {
  const LastSessionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.2,
      child: GradientCard(
        gradientVariant: Gradients.of(AppGradients.darkOne),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PhosphorIcon(PhosphorIcons.clockCounterClockwise(), size: 20, color: AppColors.accentLightBlue,),
                const SizedBox(width: 4,),
                Text(
                  'Last session',
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 20,),
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
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppColors.accentLightBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your latest workout will appear here.',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: AppColors.accentLightWhite.withAlpha(120),
                ),
              ),
              // Align(
              //   alignment: Alignment.bottomRight,
              //   child: PhosphorIcon(PhosphorIcons.clockCounterClockwise(), size: 24, color: AppColors.accentLightGray,),
              // ),
            ],
          );
        }
        return SizedBox();
      },
    );
  }
}
