import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_gradients.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/cards/gradient_card.dart';
import 'package:lifting_tracker_app/core/utils/to_upper_first.dart';
import 'package:lifting_tracker_app/features/exercises/domain/muscle_groups.dart';
import 'package:lifting_tracker_app/features/progress/presentation/pages/exercises_page.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = MuscleGroups.names;

    return Padding(
      padding: const EdgeInsetsGeometry.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MUSCLE GROUPS',
            style: Theme.of(
              context,
            ).textTheme.labelLarge!.copyWith(color: AppColors.primary),
          ),
          SizedBox(height: AppSpacing.s12),
          Expanded(
            child: GridView.builder(
              physics: ScrollPhysics(),
              itemCount: groups.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.s12,
                mainAxisSpacing: AppSpacing.s12,
                childAspectRatio: 1.5,
              ),
              itemBuilder: (context, index) {
                return MuscleGroupCard(groups[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MuscleGroupCard extends StatelessWidget {
  const MuscleGroupCard(this.muscleGroup, {super.key});

  final String muscleGroup;

  @override
  Widget build(BuildContext context) {
    final label = toUpperFirst(muscleGroup);

    return GradientCard(
      gradientVariant: AppGradients.softCard,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => ExercisesPage(muscleGroup)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s24,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.headlineSmall),
              Icon(Icons.chevron_right, color: AppColors.onSurfaceMuted),
            ],
          ),
        ),
      ),
    );
  }
}
