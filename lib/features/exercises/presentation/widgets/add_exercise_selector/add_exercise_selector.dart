import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/core/ui/transitions/sheet_parallax_route.dart';
import 'package:lifting_tracker_app/features/exercises/domain/catalog_exercise.dart';
import 'package:lifting_tracker_app/features/exercises/application/exercises_by_muscle_group_controller.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/features/exercises/presentation/widgets/add_exercise_selector/add_exercise_header.dart';
import 'package:lifting_tracker_app/features/exercises/presentation/widgets/add_exercise_selector/add_exercise_step.dart';
import 'package:lifting_tracker_app/features/exercises/presentation/widgets/add_exercise_selector/exercise_form.dart';
import 'package:lifting_tracker_app/features/exercises/presentation/widgets/add_exercise_selector/exercise_validation_dialog.dart';
import 'package:lifting_tracker_app/features/exercises/presentation/widgets/add_exercise_selector/exercises_for_a_group.dart';
import 'package:lifting_tracker_app/features/exercises/presentation/widgets/add_exercise_selector/muscle_groups_list.dart';
import 'package:lifting_tracker_app/core/ui/modal/modal_scaffold.dart';

class AddExerciseSelector extends ConsumerStatefulWidget {
  const AddExerciseSelector({super.key});

  static Future<CatalogExercise?> openExercisePickerSheet(
    BuildContext context,
  ) {
    return showModalBottomSheet<CatalogExercise>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black12,
      isScrollControlled: true,
      builder: (context) => AddExerciseSelector(),
    );
  }

  @override
  ConsumerState<AddExerciseSelector> createState() =>
      _AddExerciseSelectorState();
}

class _AddExerciseSelectorState extends ConsumerState<AddExerciseSelector> {
  final _navKey = GlobalKey<NavigatorState>();
  final _exerciseNameController = TextEditingController();
  final _newExerciseMuscleGroup = ValueNotifier<String?>(null);

  late AddExerciseStep _step;
  String? _muscleGroupPickedTitle;
  String? _muscleGroupSelected;

  CatalogExercise? _editingExercise;

  @override
  void initState() {
    super.initState();
    _step = AddExerciseStep.selectMuscleGroup;
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
      _step = AddExerciseStep.createExercise;
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

  void _openEditExercise(CatalogExercise exercise) {
    _editingExercise = exercise;
    _exerciseNameController.text = exercise.name;
    _newExerciseMuscleGroup.value = exercise.muscleGroup;

    setState(() {
      _step = AddExerciseStep.editExercise;
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
      _step = AddExerciseStep.selectMuscleGroupForNewExercise;
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
          ? AddExerciseStep.createExercise
          : AddExerciseStep.editExercise;
    });
  }

  void _openExercisesForGroup(String label, String muscleGroup) {
    setState(() {
      _muscleGroupPickedTitle = label;
      _muscleGroupSelected = muscleGroup;
      _step = AddExerciseStep.exercisesForGroup;
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
        _step = AddExerciseStep.exercisesForGroup;
      } else {
        _step = AddExerciseStep.selectMuscleGroup;
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

    try {
      final newExercise = await ref
          .read(exerciseByMuscleGroupProvider(muscleGroup).notifier)
          .addCustomExercise(name.trim(), muscleGroup);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(newExercise);
    } catch (_, _) {
      if (!mounted) return;
      SnackBarError.show(context, 'The new exercise could not be created.');
      return;
    }
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

    try {
      await ref
          .read(exerciseByMuscleGroupProvider(exercise.muscleGroup).notifier)
          .updateExercise(exercise, name.trim(), muscleGroup);

      if (!mounted) return;

      if (muscleGroup != exercise.muscleGroup) {
        ref.invalidate(exerciseByMuscleGroupProvider(muscleGroup));
      }

      _navKey.currentState?.pop();
      setState(() {
        _step = AddExerciseStep.exercisesForGroup;
        _editingExercise = null;
      });
    } catch (_, _) {
      if (!mounted) return;
      SnackBarError.show(context, 'The exercise could not be edited.');
    }
  }

  void _deleteEditingExercise() async {
    final exercise = _editingExercise;
    if (exercise == null) return;

    try {
      await ref
          .read(exerciseByMuscleGroupProvider(exercise.muscleGroup).notifier)
          .deleteExercise(exercise.id);

      if (!mounted) return;

      _navKey.currentState?.pop();
      setState(() {
        _step = AddExerciseStep.exercisesForGroup;
        _editingExercise = null;
      });
    } catch (_, _) {
      if (!mounted) return;
      SnackBarError.show(
        context,
        'The exercise could not be deleted. Try again!',
      );
    }
  }

  SheetHeaderConfig _headerFor(AddExerciseStep currentStep) {
    switch (currentStep) {
      case AddExerciseStep.selectMuscleGroup:
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
      case AddExerciseStep.createExercise:
        return SheetHeaderConfig(
          title: 'Add Exercise',
          leading: TextButton(
            onPressed: _backToMuscleGroupsOrExercises,
            style: TextButton.styleFrom(
              side: BorderSide(color: AppColors.cardBorder),
              backgroundColor: AppColors.onCardTransparent,
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
              backgroundColor: AppColors.onCardTransparent,
              side: BorderSide(color: AppColors.cardBorder),
            ),
          ),
        );
      case AddExerciseStep.exercisesForGroup:
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
      case AddExerciseStep.selectMuscleGroupForNewExercise:
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
      case AddExerciseStep.editExercise:
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
              backgroundColor: AppColors.onCardTransparent,
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
      width: MediaQuery.of(context).size.width,
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
