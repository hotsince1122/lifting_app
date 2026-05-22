import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ExerciseForm extends StatelessWidget {
  const ExerciseForm({
    required this.nameController,
    required this.selectedMuscleGroup,
    required this.onSelectMuscleGroup,
    this.onDelete,
    super.key,
  });

  final TextEditingController nameController;
  final ValueListenable<String?> selectedMuscleGroup;
  final Future<void> Function() onSelectMuscleGroup;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.card.withAlpha(253),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hint: Text(
                        'Name',
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: AppColors.onSurfaceMuted,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Divider(color: AppColors.cardBorder, thickness: 1.5),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: onSelectMuscleGroup,
                    child: ValueListenableBuilder<String?>(
                      valueListenable: selectedMuscleGroup,
                      builder: (context, muscleGroup, _) {
                        final muscleGroupLabel = muscleGroup == null
                            ? 'Muscle Group'
                            : '${muscleGroup[0].toUpperCase()}${muscleGroup.substring(1)}';

                        return Row(
                          children: [
                            Text(
                              muscleGroupLabel,
                              style: Theme.of(context).textTheme.bodyLarge!
                                  .copyWith(
                                    color: muscleGroup == null
                                        ? AppColors.onSurfaceMuted
                                        : null,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 22,
                              color: AppColors.onSurfaceMuted,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6,),
          if (onDelete != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: onDelete,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      Colors.red.withValues(alpha: 0.12),
                      AppColors.surface,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.red, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Delete',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium!.copyWith(color: Colors.red),
                      ),
                      const Spacer(),
                      PhosphorIcon(
                        PhosphorIcons.trash(PhosphorIconsStyle.regular),
                        color: Colors.red,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
