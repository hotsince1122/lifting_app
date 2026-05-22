import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/data/muscle_groups.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';

class MuscleGroupList extends StatelessWidget {
  const MuscleGroupList({required this.onSelectGroup, super.key});

  final void Function(String label, String muscleGroup) onSelectGroup;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.card.withAlpha(253),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: MuscleGroups.names.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: AppColors.cardBorder),
          itemBuilder: (context, i) {
            final muscleGroup = MuscleGroups.names[i];
            final label =
                muscleGroup[0].toUpperCase() + muscleGroup.substring(1);

            return Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
              ),
              child: ListTile(
                dense: true,
                visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
                minVerticalPadding: 0,
                contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                title: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.cardBorder,
                ),
                onTap: () {
                  onSelectGroup(label, muscleGroup);
                },
                splashColor: Colors.transparent,
              ),
            );
          },
        ),
      ),
    );
  }
}
