import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/data/queries/save_progress.dart';
import 'package:lifting_tracker_app/models/entity/training_set.dart';
import 'package:lifting_tracker_app/providers/persisted/exercise_and_sets/exercises_and_sets.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';

class ExerciseSetTile extends ConsumerStatefulWidget {
  const ExerciseSetTile(
    this.set,
    this.setIndex,
    this.iconSize,
    this.workoutSessionId,
    this.exerciseId,
    this.exerciseOrderIndex, {
    super.key,
  });

  final TrainingSet set;
  final int setIndex;
  final double iconSize;
  final int workoutSessionId;
  final String exerciseId;
  final int exerciseOrderIndex;

  @override
  ConsumerState<ExerciseSetTile> createState() => _ExerciseSetTileState();
}

class _ExerciseSetTileState extends ConsumerState<ExerciseSetTile> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late TextEditingController _notesController;

  Timer? _debounceTimer;

  late final ExercisesAndSetsProvider _exercisesAndSetsNotifier;

  @override
  void initState() {
    super.initState();

    _exercisesAndSetsNotifier = ref.read(
      exercisesAndSetsProvider(widget.workoutSessionId).notifier,
    );

    final actualWeight = widget.set.actualWeight;
    final weightText = actualWeight == null
        ? ''
        : actualWeight == actualWeight.toInt()
        ? actualWeight.toInt().toString()
        : actualWeight.toString();

    _weightController = TextEditingController(text: weightText);

    _repsController = TextEditingController(
      text: widget.set.actualRepetitions?.toString() ?? '',
    );
    _notesController = TextEditingController(
      text: widget.set.actualNotes?.toString() ?? '',
    );
  }

  void _scheduleSave() {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      _saveNow();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _saveToDbOnly();

    _weightController.dispose();
    _repsController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  Future<void> _saveNow() async {
    final setId = widget.set.activeSessionSetId;
    if (setId == null) return;

    _exercisesAndSetsNotifier.saveSetCell(
      setId,
      double.tryParse(_weightController.text),
      int.tryParse(_repsController.text),
      _notesController.text.trim().isEmpty ? null : _notesController.text,
      widget.exerciseId,
      widget.exerciseOrderIndex,
    );
  }

  Future<void> _saveToDbOnly() async {
    final setId = widget.set.activeSessionSetId;
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

    Widget indexContainer(int setIndex) {
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
            (setIndex + 1).toString(),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        indexContainer(widget.setIndex),
        const SizedBox(width: 16),

        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(width: 54, child: cellLabel('Kg')),
                SizedBox(width: 54, child: cellLabel('Reps')),
                SizedBox(width: 152, child: cellLabel('Notes')),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 54,
                  child: cellField(
                    weightLabel,
                    _weightController,
                    isNotes: false,
                    isReps: false,
                  ),
                ),
                SizedBox(
                  width: 54,
                  child: cellField(
                    widget.set.hintRepetitions.toString(),
                    _repsController,
                    isNotes: false,
                    isReps: true,
                  ),
                ),
                SizedBox(
                  width: 152,
                  child: cellField(
                    widget.set.hintNotes,
                    _notesController,
                    isNotes: true,
                    isReps: false,
                  ),
                ),
              ],
            ),
          ],
        ),

        const Spacer(),
        SizedBox(
          width: 29,
          height: 44,
          child: InkWell(
            splashFactory: NoSplash.splashFactory,
            onTap: () {},
            child: PhosphorIcon(
              PhosphorIcons.dotsThree(PhosphorIconsStyle.bold),
              color: AppColors.secondary,
              size: widget.iconSize,
            ),
          ),
        ),
      ],
    );
  }
}
