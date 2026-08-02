import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/features/workouts/data/workout_set_commands.dart';
import 'package:lifting_tracker_app/features/workouts/application/session_editor/workout_session_exercises_controller.dart';
import 'package:lifting_tracker_app/features/workouts/domain/training_set.dart';

import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/view_data/workout_set_focus_nodes.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/set_settings_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';

class ExerciseSetTile extends ConsumerStatefulWidget {
  const ExerciseSetTile(
    this.set,
    this.setIndex,
    this.iconSize,
    this.workoutSessionId,
    this.exerciseId,
    this.exerciseOrderIndex,
    this.horizontalPadding, {
    required this.onDeleteSet,
    required this.focusNodes,
    super.key,
  });

  final TrainingSet set;
  final int? setIndex;
  final double iconSize;
  final int workoutSessionId;
  final String exerciseId;
  final int exerciseOrderIndex;
  final double horizontalPadding;
  final Future<void> Function() onDeleteSet;
  final WorkoutSetFocusNodes focusNodes;

  @override
  ConsumerState<ExerciseSetTile> createState() => _ExerciseSetTileState();
}

class _ExerciseSetTileState extends ConsumerState<ExerciseSetTile> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late TextEditingController _notesController;

  Timer? _debounceTimer;

  late final WorkoutSessionExercisesController _exercisesAndSetsNotifier;

  static const double _smallCellWidth = 56.0;

  @override
  void initState() {
    super.initState();

    _exercisesAndSetsNotifier = ref.read(
      workoutSessionExercisesProvider(widget.workoutSessionId).notifier,
    );

    _weightController = TextEditingController();
    _repsController = TextEditingController();
    _notesController = TextEditingController();

    _syncControllersWithSet();
  }

  String _weightText(double? actualWeight) {
    if (actualWeight == null) return '';

    return actualWeight == actualWeight.toInt()
        ? actualWeight.toInt().toString()
        : actualWeight.toString();
  }

  void _syncControllerText(TextEditingController controller, String text) {
    if (controller.text == text) return;

    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _syncControllersWithSet() {
    _syncControllerText(
      _weightController,
      _weightText(widget.set.actualWeight),
    );
    _syncControllerText(
      _repsController,
      widget.set.actualRepetitions?.toString() ?? '',
    );
    _syncControllerText(_notesController, widget.set.actualNotes ?? '');
  }

  @override
  void didUpdateWidget(covariant ExerciseSetTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.set.actualWeight != widget.set.actualWeight ||
        oldWidget.set.actualRepetitions != widget.set.actualRepetitions ||
        oldWidget.set.actualNotes != widget.set.actualNotes) {
      _syncControllersWithSet();
    }
  }

  void _scheduleSave() {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      unawaited(_saveNow());
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    unawaited(_saveToDbOnly().catchError((_) {}));

    _weightController.dispose();
    _repsController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  Future<void> _saveNow() async {
    final setId = widget.set.workoutSessionSetId;
    if (setId == null) return;

    try {
      await _exercisesAndSetsNotifier.saveSetCell(
        setId,
        double.tryParse(_weightController.text),
        int.tryParse(_repsController.text),
        _notesController.text.trim().isEmpty ? null : _notesController.text,
        widget.exerciseId,
        widget.exerciseOrderIndex,
      );
    } catch (_) {
      if (!mounted) return;
      SnackBarError.show(
        context,
        'Could not save set changes. Please try again.',
      );
    }
  }

  Future<void> _saveToDbOnly() async {
    final setId = widget.set.workoutSessionSetId;
    if (setId == null) return;

    await saveSetCellToDb(
      setId,
      double.tryParse(_weightController.text),
      int.tryParse(_repsController.text),
      _notesController.text.trim().isEmpty ? null : _notesController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    Widget cellLabel(String text) {
      return Text(
        text,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    Widget cellField(
      String hintText,
      TextEditingController controller, {
      required FocusNode focusNode,
      required bool isNotes,
      required bool isReps,
    }) {
      final hintStyle = isNotes
          ? Theme.of(context).textTheme.bodyLarge!.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.onSurfaceMuted,
            )
          : Theme.of(context).textTheme.headlineSmall!.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.onSurfaceMuted,
            );

      final textStyle = isNotes
          ? Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.onSurface,
            )
          : Theme.of(context).textTheme.headlineSmall!.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.onSurface,
            );

      final List<TextInputFormatter>? inputFormater;

      if (isReps) {
        inputFormater = [FilteringTextInputFormatter.allow(RegExp(r'^\d*$'))];
      } else if (isNotes) {
        inputFormater = null;
      } else {
        inputFormater = [
          TextInputFormatter.withFunction((oldValue, newValue) {
            final text = newValue.text;
            final isValid = RegExp(r'^\d*\.?\d*$').hasMatch(text);

            return isValid ? newValue : oldValue;
          }),
        ];
      }

      return TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: (_) => _scheduleSave(),
        keyboardType: isNotes
            ? TextInputType.multiline
            : isReps
            ? TextInputType.number
            : const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: inputFormater,
        minLines: 1,
        maxLines: isNotes ? null : 1,
        decoration: InputDecoration(
          hintText: hintText,
          hintMaxLines: isNotes ? null : 1,
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
          hintStyle: hintStyle,
        ),
        style: textStyle,
      );
    }

    Widget indexContainer(int? setIndex) {
      return Container(
        height: widget.iconSize,
        width: widget.iconSize,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: BoxBorder.all(color: AppColors.onSurface),
        ),
        child: Center(
          child: Text(
            setIndex?.toString() ?? '',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final weightLabel = widget.set.hintWeight == widget.set.hintWeight.toInt()
        ? widget.set.hintWeight.toInt().toString()
        : widget.set.hintWeight.toString();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          indexContainer(widget.setIndex),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(width: _smallCellWidth, child: cellLabel('Kg')),
                    SizedBox(width: _smallCellWidth, child: cellLabel('Reps')),
                    Expanded(child: cellLabel('Notes')),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: _smallCellWidth,
                      child: cellField(
                        weightLabel,
                        _weightController,
                        focusNode: widget.focusNodes.weight,
                        isNotes: false,
                        isReps: false,
                      ),
                    ),
                    SizedBox(
                      width: _smallCellWidth,
                      child: cellField(
                        widget.set.hintRepetitions.toString(),
                        _repsController,
                        focusNode: widget.focusNodes.reps,
                        isNotes: false,
                        isReps: true,
                      ),
                    ),
                    Expanded(
                      child: cellField(
                        widget.set.hintNotes,
                        _notesController,
                        focusNode: widget.focusNodes.notes,
                        isNotes: true,
                        isReps: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                customBorder: const CircleBorder(),
                splashFactory: NoSplash.splashFactory,
                onTap: () async {
                  await SetSettingsSheet.openSetSettings(
                    context,
                    screenWidth,
                    widget.set.workoutSessionSetId!,
                    widget.set.isWarmup!,
                    widget.workoutSessionId,
                    widget.onDeleteSet,
                  );
                },
                child: Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: PhosphorIcon(
                    PhosphorIcons.dotsThree(PhosphorIconsStyle.bold),
                    color: AppColors.secondary,
                    size: widget.iconSize,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
