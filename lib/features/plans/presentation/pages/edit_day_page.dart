import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/features/exercises/presentation/widgets/add_exercise_selector/add_exercise_selector.dart';
import 'package:lifting_tracker_app/features/plans/application/planned_exercises_controller.dart';
import 'package:lifting_tracker_app/features/plans/presentation/editor/delete_flow/delete_day_flow.dart';
import 'package:lifting_tracker_app/features/plans/presentation/widgets/add_to_split.dart';
import 'package:lifting_tracker_app/features/plans/presentation/widgets/delete_validation.dart';
import 'package:lifting_tracker_app/core/ui/app_bars/simple_app_bar.dart';
import 'package:lifting_tracker_app/features/plans/presentation/widgets/change_name.dart';
import 'package:lifting_tracker_app/features/plans/presentation/editor/change_name_flow/change_day_name_flow.dart';
import 'package:lifting_tracker_app/features/plans/presentation/widgets/exercises.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class EditDayPage extends ConsumerWidget {
  const EditDayPage(this.dayId, this.splitId, {super.key});

  final String dayId;
  final int splitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: SimpleAppBar('Edit day', isTitleCentered: true),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          clipBehavior: Clip.none,
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.s16,
              right: AppSpacing.s16,
              bottom: AppSpacing.s32,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ChangeName(
                    flow: ChangeDayNameFlow(dayId: dayId),
                    key: ValueKey(dayId),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  Exercises(dayId),
                  const SizedBox(height: AppSpacing.s16),
                  AddToSplit(
                    buttonLabel: 'Add exercise',
                    addFunction: () async {
                      final addedExercise =
                          await AddExerciseSelector.openExercisePickerSheet(
                            context,
                          );

                      if (!context.mounted || addedExercise == null) return;

                      try {
                        await ref
                            .read(plannedExercisesProvider(dayId).notifier)
                            .addExerciseToDay(addedExercise.id);
                      } catch (_) {
                        if (!context.mounted) return;

                        SnackBarError.show(
                          context,
                          'Exercise could not be added. Try again.',
                        );
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.s48),
                  TextButton.icon(
                    onPressed: () async {
                      final wasDeleted = await showDeleteValidation(
                        context,
                        DeleteDayFlow(splitId: splitId, dayId: dayId, ref: ref),
                      );

                      if (wasDeleted && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: Icon(
                      PhosphorIcons.trash(),
                      color: Colors.red,
                      size: 18,
                    ),
                    label: Text(
                      'Delete day',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium!.copyWith(color: Colors.red),
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
