import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/entity/exercise.dart';
import 'package:lifting_tracker_app/providers/persisted/exercise_and_sets/exercises_and_sets.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/active_session_screen/reorder_exercises_sheet.dart';
import 'package:lifting_tracker_app/widgets/add_exercise_selector.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ExerciseSettings extends ConsumerStatefulWidget {
  const ExerciseSettings(
    this.screenWidth,
    this.activeSessionId,
    this.exercise, {
    required this.onDelete,
    super.key,
  });

  final double screenWidth;
  final int activeSessionId;
  final Exercise exercise;
  final Future<void> Function() onDelete;

  static Future<void> openExerciseSettings(
    BuildContext context,
    double screenWidth,
    int activeSessionId,
    Exercise exercise,
    Future<void> Function() onDelete,
  ) {
    return showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black12,
      isScrollControlled: true,
      builder: (context) => ExerciseSettings(
        screenWidth,
        activeSessionId,
        exercise,
        onDelete: onDelete,
      ),
    );
  }

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      ExerciseSettingsState();
}

class ExerciseSettingsState extends ConsumerState<ExerciseSettings> {
  Widget _settingCell(
    String settingName,
    IconData settingIcon,
    Function() onTap,
  ) {
    final isDeleteCell = settingName == 'Delete';

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(settingIcon, color: isDeleteCell ? Colors.red : null),
            const SizedBox(height: 2),
            Text(
              settingName,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w500,
                color: isDeleteCell ? Colors.red : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _separator() {
    return Container(width: 1.5, height: 36, color: AppColors.cardBorder);
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.4,
            width: widget.screenWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: AppColors.card.withAlpha(253),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          widget.exercise.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            iconSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: BoxBorder.all(
                          color: AppColors.cardBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          _settingCell('Move', Icons.reorder, () async {
                            Navigator.of(context).pop();
                            await Future.delayed(
                              const Duration(milliseconds: 150),
                            );
                            if (!context.mounted) return;
                            ReorderExercisesSheet.openSheet(
                              context,
                              widget.screenWidth,
                              widget.activeSessionId,
                            );
                          }),
                          _separator(),
                          _settingCell(
                            'Replace',
                            PhosphorIcons.arrowsClockwise(),
                            () async {
                              final exerciseToReplace = widget.exercise;
                              final exercisesNotifier = ref.read(
                                exercisesAndSetsProvider(
                                  widget.activeSessionId,
                                ).notifier,
                              );

                              await Future.delayed(
                                const Duration(milliseconds: 150),
                              );

                              if (!context.mounted) return;

                              final selectedExercise =
                                  await AddExerciseSelector.openExercisePickerSheet(
                                    context,
                                    widget.screenWidth,
                                  );

                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }

                              if (selectedExercise != null) {
                                await exercisesNotifier.replaceExercise(
                                  exerciseToReplace,
                                  selectedExercise,
                                );
                              }
                            },
                          ),
                          _separator(),
                          _settingCell('Delete', Icons.close, () async {
                            Navigator.of(context).pop();
                            await widget.onDelete();
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
