import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/features/workouts/application/session_editor/workout_session_exercises_controller.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/features/workouts/domain/workout_exercise.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/exercise_card_components/exercise_set_tile.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/exercise_card_components/exercise_tile_footer.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/exercise_card_components/exercise_tile_header.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/exercise_card_components/inserted_set_animation.dart';
import 'package:lifting_tracker_app/core/ui/cards/solid_card.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/widgets/exercise_settings_sheet.dart';

class WorkoutExerciseCard extends ConsumerStatefulWidget {
  const WorkoutExerciseCard(
    this.exerciseAndItsSets,
    this.workoutSessionId,
    this.horizontalPaddingForCard, {
    super.key,
  });

  final WorkoutExercise exerciseAndItsSets;
  final int workoutSessionId;
  final double horizontalPaddingForCard;

  @override
  ConsumerState<WorkoutExerciseCard> createState() =>
      _WorkoutExerciseCardState();
}

class _WorkoutExerciseCardState extends ConsumerState<WorkoutExerciseCard> {
  final double _verticalPaddig = 20;
  final double _horizontalPadding = 20;
  final double _iconSize = 28;
  final double _paddingBetween = 24;
  final double _iconTouchTarget = 46;

  bool _isDeletingExercise = false;
  bool _isCollapsed = false;

  static const _fadeDuration = Duration(milliseconds: 250);
  static const _collapseDuration = Duration(milliseconds: 250);

  int? _newAddedSetIndex;

  @override
  void didUpdateWidget(covariant WorkoutExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final isSameExercise =
        oldWidget.exerciseAndItsSets.catalogExercise.id ==
            widget.exerciseAndItsSets.catalogExercise.id &&
        oldWidget.exerciseAndItsSets.orderIndex ==
            widget.exerciseAndItsSets.orderIndex;

    final oldCount = oldWidget.exerciseAndItsSets.sets.length;
    final newCount = widget.exerciseAndItsSets.sets.length;

    if (!isSameExercise || newCount < oldCount) {
      _newAddedSetIndex = null;
      return;
    }

    if (oldCount < newCount) {
      _newAddedSetIndex = newCount - 1;
    }
  }

  void _clearNewAddedSetIndex(int setIndex) {
    if (!mounted || _newAddedSetIndex != setIndex) return;

    setState(() {
      _newAddedSetIndex = null;
    });
  }

  Widget _hp(Widget child) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: child,
    );
  }

  Widget _separator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: const Divider(height: 1, color: AppColors.cardBorder),
    );
  }

  Widget _dismissibleSet(
    String exerciseId,
    int exerciseOrderIndex,
    Object dismissIdentity,
    int workoutSessionSetId,
    bool isLastSetRemaining,
    Widget child,
  ) {
    return Dismissible(
      key: ValueKey(dismissIdentity),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: const Alignment(0.95, 0),
        width: double.infinity,
        height: double.infinity,
        color: Colors.red,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Icon(Icons.delete_outline_outlined),
      ),
      confirmDismiss: (_) async {
        if (isLastSetRemaining) {
          return _animateAndDeleteExercise(exerciseId, exerciseOrderIndex);
        }

        return _removeSet(workoutSessionSetId);
      },
      child: child,
    );
  }

  Widget _buildSet(
    WorkoutExercise exercise,
    int exerciseOrderIndex,
    int setIndexUI,
  ) {
    final exerciseId = exercise.catalogExercise.id;
    final set = exercise.sets[setIndexUI];
    final isLastSetRemaining = exercise.sets.length == 1;
    final displaySetIndex = set.isWarmup == true
        ? null
        : exercise.sets
              .take(setIndexUI + 1)
              .where((set) => set.isWarmup != true)
              .length;
    final setIdentity =
        set.workoutSessionSetId ??
        (exerciseId, exercise.orderIndex, set.setIndex, setIndexUI);
    final workoutSessionSetId = set.workoutSessionSetId!;

    Future<void> deleteSetFromSettings() async {
      if (isLastSetRemaining) {
        await _animateAndDeleteExercise(exerciseId, exerciseOrderIndex);
        return;
      }

      await _removeSet(workoutSessionSetId);
    }

    final child = Column(
      children: [
        if (setIndexUI > 0) _separator(),
        _dismissibleSet(
          exerciseId,
          exerciseOrderIndex,
          setIdentity,
          workoutSessionSetId,
          isLastSetRemaining,
          _hp(
            Column(
              children: [
                SizedBox(height: _paddingBetween / 2),
                ExerciseSetTile(
                  set,
                  displaySetIndex,
                  _iconSize,
                  widget.workoutSessionId,
                  exerciseId,
                  exercise.orderIndex,
                  onDeleteSet: deleteSetFromSettings,
                  key: ValueKey(setIdentity),
                ),
                SizedBox(height: _paddingBetween / 2),
              ],
            ),
          ),
        ),
      ],
    );

    if (setIndexUI == _newAddedSetIndex) {
      return InsertedSetAnimation(
        key: ValueKey((
          exerciseId,
          exercise.orderIndex,
          setIndexUI,
          exercise.sets.length,
        )),
        onCompleted: () => _clearNewAddedSetIndex(setIndexUI),
        child: child,
      );
    }

    return child;
  }

  Widget _dismissibleExercise(
    String exerciseId,
    int exerciseOrderIndex,
    Widget child,
  ) {
    return Dismissible(
      key: ValueKey((exerciseId, exerciseOrderIndex)),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: const Alignment(0.95, 0),
        width: double.infinity,
        height: double.infinity,
        color: Colors.red,
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Icon(Icons.delete_outline_outlined),
      ),
      confirmDismiss: (_) async {
        return _animateAndDeleteExercise(exerciseId, exerciseOrderIndex);
      },
      child: child,
    );
  }

  Widget _buildHeader(WorkoutExercise exercise, double iconSize) {
    return _dismissibleExercise(
      exercise.catalogExercise.id,
      exercise.orderIndex,
      Padding(
        padding: EdgeInsets.only(
          top: _verticalPaddig,
          bottom: _paddingBetween / 2,
        ),
        child: _hp(ExerciseTileHeader(exercise, _iconSize)),
      ),
    );
  }

  Future<void> _playExerciseExitAnimation() async {
    if (_isDeletingExercise || _isCollapsed) return;

    setState(() {
      _isDeletingExercise = true;
    });

    await Future.delayed(_fadeDuration);

    if (!mounted) return;

    setState(() {
      _isCollapsed = true;
    });
  }

  Future<bool> _animateAndDeleteExercise(
    String exerciseId,
    int exerciseOrderIndex,
  ) async {
    await _playExerciseExitAnimation();

    if (!mounted) return false;

    try {
      await ref
          .read(
            workoutSessionExercisesProvider(widget.workoutSessionId).notifier,
          )
          .deleteExercise(exerciseId, exerciseOrderIndex);
    } catch (_) {
      if (!mounted) return false;

      setState(() {
        _isDeletingExercise = false;
        _isCollapsed = false;
      });

      SnackBarError.show(
        context,
        'Could not delete exercise. Please try again.',
      );
    }

    return false;
  }

  Future<bool> _removeSet(int workoutSessionSetId) async {
    try {
      await ref
          .read(
            workoutSessionExercisesProvider(widget.workoutSessionId).notifier,
          )
          .removeSetFromExercise(workoutSessionSetId);
    } catch (_) {
      if (!mounted) return false;

      SnackBarError.show(context, 'Could not delete set. Please try again.');
    }

    return false;
  }

  Widget _visualLayer(WorkoutExercise exercise) {
    final exerciseOrderIndex = exercise.orderIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(exercise, _iconSize),
        _separator(),
        for (int indexUI = 0; indexUI < exercise.sets.length; indexUI++) ...[
          _buildSet(exercise, exerciseOrderIndex, indexUI),
        ],
        if (exercise.sets.isNotEmpty) ...{
          _separator(),
          SizedBox(height: _paddingBetween / 2),
        },
        _hp(ExerciseTileFooter(exercise)),
      ],
    );
  }

  List<Widget> _interactivLayer(WorkoutExercise exercise, double screenWidth) {
    Future<void> deleteExerciseFromSettings() async {
      await _animateAndDeleteExercise(
        exercise.catalogExercise.id,
        exercise.orderIndex,
      );
      return;
    }

    return [
      Positioned(
        top: 11,
        right: 11,
        width: _iconTouchTarget,
        height: _iconTouchTarget,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashColor: Colors.transparent,
            splashFactory: InkSplash.splashFactory,
            highlightColor: Colors.transparent,
            borderRadius: BorderRadius.circular(_iconTouchTarget / 2),
            onTap: () {
              ExerciseSettingsSheet.openExerciseSettings(
                context,
                screenWidth,
                widget.workoutSessionId,
                exercise,
                deleteExerciseFromSettings,
              );
            },
          ),
        ),
      ),
      ExerciseTileFooter.exerciseTileFooterOnTap(
        exercise,
        ref,
        widget.workoutSessionId,
        context,
      ),
      Positioned(
        bottom: 8,
        right: 56,
        height: _iconTouchTarget,
        width: _iconTouchTarget,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(_iconTouchTarget / 2),
            onTap: () {},
          ),
        ),
      ),
      Positioned(
        bottom: 8,
        right: 8,
        height: _iconTouchTarget,
        width: _iconTouchTarget,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(_iconTouchTarget / 2),
            onTap: () {},
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exerciseAndItsSets;
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedSize(
      duration: _collapseDuration,
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: _isCollapsed
          ? SizedBox.shrink()
          : AnimatedScale(
              duration: _fadeDuration,
              curve: Curves.easeOut,
              scale: _isDeletingExercise ? 0.6 : 1,
              child: AnimatedOpacity(
                duration: _fadeDuration,
                opacity: _isDeletingExercise ? 0.6 : 1,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.horizontalPaddingForCard,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: AnimatedSlide(
                      duration: _fadeDuration,
                      curve: Curves.easeOutCubic,
                      offset: _isDeletingExercise
                          ? const Offset(-1.5, 0)
                          : Offset.zero,
                      child: SolidCard(
                        padding: EdgeInsets.zero,
                        child: Stack(
                          children: [
                            AnimatedSize(
                              duration: _fadeDuration,
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: _verticalPaddig,
                                ),
                                child: _visualLayer(exercise),
                              ),
                            ),
                            ..._interactivLayer(exercise, screenWidth),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
