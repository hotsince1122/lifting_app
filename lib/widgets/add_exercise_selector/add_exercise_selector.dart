import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/animations/custom_nav_animation.dart';
import 'package:lifting_tracker_app/models/entity/exercise.dart';
import 'package:lifting_tracker_app/providers/persisted/all_exercises_from_a_muscle_group.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/add_exercise_selector/add_exercise_header.dart';
import 'package:lifting_tracker_app/widgets/add_exercise_selector/add_exercise_step.dart';
import 'package:lifting_tracker_app/widgets/add_exercise_selector/exercise_form.dart';
import 'package:lifting_tracker_app/widgets/add_exercise_selector/exercise_validation_dialog.dart';
import 'package:lifting_tracker_app/widgets/add_exercise_selector/exercises_for_a_group.dart';
import 'package:lifting_tracker_app/widgets/add_exercise_selector/muscle_groups_list.dart';
import 'package:lifting_tracker_app/widgets/modal_scaffold.dart';

class AddExerciseSelector extends ConsumerStatefulWidget {
  const AddExerciseSelector(this.screenWidth, {super.key});

  final double screenWidth;

  static Future<Exercise?> openExercisePickerSheet(
    BuildContext context,
    double screenWidth,
  ) {
    return showModalBottomSheet<Exercise>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black12,
      isScrollControlled: true,
      builder: (context) => AddExerciseSelector(screenWidth),
    );
  }

  @override
  ConsumerState<AddExerciseSelector> createState() =>
      AddExerciseSelectorState();
}

class AddExerciseSelectorState extends ConsumerState<AddExerciseSelector> {
  final _navKey = GlobalKey<NavigatorState>();
  final _exerciseNameController = TextEditingController();
  final _newExerciseMuscleGroup = ValueNotifier<String?>(null);

  late AddExerciseStep _step;
  String? _muscleGroupPickedTitle;
  String? _muscleGroupSelected;

  Exercise? _editingExercise;

  @override
  void initState() {
    super.initState();
    _step = AddExerciseStep.selectMuscleGroupStep;
  }

  @override
  void dispose() {
    _exerciseNameController.dispose();
    _newExerciseMuscleGroup.dispose();
    super.dispose();
  }

  void _closeSheet() {
    Navigator.of(context).pop();
  }

  void _openCreateExercise({String? fromMuscleGroup}) {
    _editingExercise = null;
    _exerciseNameController.clear();
    _newExerciseMuscleGroup.value = fromMuscleGroup;

    setState(() {
      _step = AddExerciseStep.createExerciseStep;
    });

    _navKey.currentState?.push(
      sheetParallaxRoute(
        ExerciseForm(
          nameController: _exerciseNameController,
          selectedMuscleGroup: _newExerciseMuscleGroup,
          onSelectMuscleGroup: _selectMuscleGroupForNewExercise,
          onDelete: null,
        ),
      ),
    );
  }

  void _openEditExercise(Exercise exercise) {
    _editingExercise = exercise;
    _exerciseNameController.text = exercise.name;
    _newExerciseMuscleGroup.value = exercise.muscleGroup;

    setState(() {
      _step = AddExerciseStep.editExerciseStep;
    });

    _navKey.currentState?.push(
      sheetParallaxRoute(
        ExerciseForm(
          nameController: _exerciseNameController,
          selectedMuscleGroup: _newExerciseMuscleGroup,
          onSelectMuscleGroup: _selectMuscleGroupForNewExercise,
          onDelete: _deleteEditingExercise,
        ),
      ),
    );
  }

  Future<void> _selectMuscleGroupForNewExercise() async {
    setState(() {
      _step = AddExerciseStep.selectMuscleGroupForNewExerciseStep;
    });

    final pickedMuscleGroup = await _navKey.currentState?.push<String>(
      sheetParallaxRoute(
        MuscleGroupList(
          onSelectGroup: (_, muscleGroup) {
            _navKey.currentState?.pop(muscleGroup);
          },
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (pickedMuscleGroup != null) {
      _newExerciseMuscleGroup.value = pickedMuscleGroup;
    }

    setState(() {
      _step = _editingExercise == null
          ? AddExerciseStep.createExerciseStep
          : AddExerciseStep.editExerciseStep;
    });
  }

  void _openExercisesForGroup(String label, String muscleGroup) {
    setState(() {
      _muscleGroupPickedTitle = label;
      _muscleGroupSelected = muscleGroup;
      _step = AddExerciseStep.exercisesForGroupStep;
    });

    _navKey.currentState?.push(
      sheetParallaxRoute(
        ExercisesForGroupPage(muscleGroup, onEditExercise: _openEditExercise),
      ),
    );
  }

  void _backToMuscleGroupsOrExercises() {
    _navKey.currentState?.pop();

    final canPop = _navKey.currentState?.canPop() == true;

    setState(() {
      if (canPop) {
        _step = AddExerciseStep.exercisesForGroupStep;
      } else {
        _step = AddExerciseStep.selectMuscleGroupStep;
      }
    });
  }

  void addCustomExercise(String? name, String? muscleGroup) async {
    final isValid = await showExerciseValidationDialog(
      context,
      name: name,
      muscleGroup: muscleGroup,
    );

    if (!mounted || !isValid || muscleGroup == null || name == null) return;

    final newExercise = await ref
        .read(exercisesFromAMuscleGroup(muscleGroup).notifier)
        .addCustomExercise(name.trim(), muscleGroup);

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(newExercise);
  }

  void _saveEditingExercise(String? name, String? muscleGroup) async {
    final exercise = _editingExercise;
    final isValid = await showExerciseValidationDialog(
      context,
      name: name,
      muscleGroup: muscleGroup,
    );

    if (!mounted ||
        !isValid ||
        exercise == null ||
        muscleGroup == null ||
        name == null) {
      return;
    }

    await ref
        .read(exercisesFromAMuscleGroup(exercise.muscleGroup).notifier)
        .updateExercise(exercise, name.trim(), muscleGroup);

    if (muscleGroup != exercise.muscleGroup) {
      ref.invalidate(exercisesFromAMuscleGroup(muscleGroup));
    }

    _navKey.currentState?.pop();
    setState(() {
      _step = AddExerciseStep.exercisesForGroupStep;
      _editingExercise = null;
    });
  }

  void _deleteEditingExercise() async {
    final exercise = _editingExercise;
    if (exercise == null) return;

    await ref
        .read(exercisesFromAMuscleGroup(exercise.muscleGroup).notifier)
        .removeExercise(exercise.id);

    if (!mounted) return;

    _navKey.currentState?.pop();
    setState(() {
      _step = AddExerciseStep.exercisesForGroupStep;
      _editingExercise = null;
    });
  }

  SheetHeaderConfig _headerFor(AddExerciseStep currentStep) {
    switch (currentStep) {
      case AddExerciseStep.selectMuscleGroupStep:
        return SheetHeaderConfig(
          title: 'Select Muscle Group',
          leading: IconButton(
            onPressed: _closeSheet,
            icon: const Icon(Icons.close),
          ),
          trailing: IconButton(
            onPressed: _openCreateExercise,
            icon: const Icon(Icons.add),
          ),
        );
      case AddExerciseStep.createExerciseStep:
        return SheetHeaderConfig(
          title: 'Add Exercise',
          leading: TextButton(
            onPressed: _backToMuscleGroupsOrExercises,
            style: TextButton.styleFrom(
              side: BorderSide(color: AppColors.cardBorder),
              backgroundColor: AppColors.surface.withAlpha(75),
            ),
            child: Text(
              'Cancel',
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: AppColors.onSurface),
            ),
          ),
          trailing: IconButton(
            onPressed: () {
              addCustomExercise(
                _exerciseNameController.text.trim(),
                _newExerciseMuscleGroup.value,
              );
            },
            icon: Icon(Icons.check),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface.withAlpha(75),
              side: BorderSide(color: AppColors.cardBorder),
            ),
          ),
        );
      case AddExerciseStep.exercisesForGroupStep:
        return SheetHeaderConfig(
          title: _muscleGroupPickedTitle ?? 'Select Exercise',
          leading: IconButton(
            onPressed: _backToMuscleGroupsOrExercises,
            iconSize: 24,
            icon: Icon(Icons.arrow_back_ios_rounded),
          ),
          trailing: IconButton(
            onPressed: () {
              _openCreateExercise(fromMuscleGroup: _muscleGroupSelected);
            },
            icon: const Icon(Icons.add),
          ),
        );
      case AddExerciseStep.selectMuscleGroupForNewExerciseStep:
        return SheetHeaderConfig(
          title: 'Select Muscle Group',
          leading: IconButton(
            onPressed: () {
              _navKey.currentState?.pop();
            },
            iconSize: 18,
            icon: Icon(Icons.arrow_back_ios_rounded),
          ),
          trailing: null,
        );
      case AddExerciseStep.editExerciseStep:
        return SheetHeaderConfig(
          title: 'Edit Exercise',
          leading: IconButton(
            onPressed: _backToMuscleGroupsOrExercises,
            iconSize: 18,
            icon: Icon(Icons.arrow_back_ios_rounded),
          ),
          trailing: IconButton(
            onPressed: () {
              _saveEditingExercise(
                _exerciseNameController.text.trim(),
                _newExerciseMuscleGroup.value,
              );
            },
            icon: Icon(Icons.check),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface.withAlpha(75),
              side: BorderSide(color: AppColors.cardBorder),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModalScaffold(
      height: 0.75,
      width: widget.screenWidth,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: SheetHeader(config: _headerFor(_step)),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Navigator(
              clipBehavior: Clip.hardEdge,
              key: _navKey,
              onGenerateRoute: (_) {
                return sheetParallaxRoute(
                  MuscleGroupList(
                    onSelectGroup: (label, muscleGroup) {
                      _openExercisesForGroup(label, muscleGroup);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
