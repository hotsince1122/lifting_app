import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/entity/exercise.dart';
import 'package:lifting_tracker_app/providers/persisted/exercise_and_sets/exercises_and_sets.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/active_session_screen/exercise_card_components/exercise_set_tile.dart';
import 'package:lifting_tracker_app/widgets/active_session_screen/exercise_card_components/exercise_tile_footer.dart';
import 'package:lifting_tracker_app/widgets/active_session_screen/exercise_card_components/exercise_tile_header.dart';
import 'package:lifting_tracker_app/widgets/active_session_screen/exercise_card_components/insert_set_animation.dart';
import 'package:lifting_tracker_app/widgets/active_session_screen/exercise_settings.dart';
import 'package:lifting_tracker_app/widgets/solid_card.dart';

class ExerciseAndSetsCard extends ConsumerStatefulWidget {
  const ExerciseAndSetsCard(
    this.exerciseAndItsSets,
    this.workoutSessionId,
    this.horizontalPaddingForCard, {
    super.key,
  });

  final Exercise exerciseAndItsSets;
  final int workoutSessionId;
  final double horizontalPaddingForCard;

  @override
  ConsumerState<ExerciseAndSetsCard> createState() =>
      _ExerciseAndSetsCardState();
}

class _ExerciseAndSetsCardState extends ConsumerState<ExerciseAndSetsCard> {
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
  void didUpdateWidget(covariant ExerciseAndSetsCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final isSameExercise =
        oldWidget.exerciseAndItsSets.id == widget.exerciseAndItsSets.id &&
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
    int activeSessionSetId,
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
        if (!isLastSetRemaining) return true;

        return _animateAndDeleteExercise(exerciseId, exerciseOrderIndex);
      },
      onDismissed: (_) async {
        if (isLastSetRemaining) return;

        await ref
            .read(exercisesAndSetsProvider(widget.workoutSessionId).notifier)
            .removeSetFromExercise(activeSessionSetId);
      },
      child: child,
    );
  }

  Widget _buildSet(Exercise exercise, int exerciseOrderIndex, int setIndexUI) {
    final set = exercise.sets[setIndexUI];
    final isLastSetRemaining = exercise.sets.length == 1;
    final displaySetIndex = set.isWarmup == true
        ? null
        : exercise.sets
              .take(setIndexUI + 1)
              .where((set) => set.isWarmup != true)
              .length;
    final setIdentity =
        set.activeSessionSetId ??
        (exercise.id, exercise.orderIndex, set.setIndex, setIndexUI);
    final activeSessionSetId = set.activeSessionSetId!;

    Future<void> deleteSetFromSettings() async {
      if (isLastSetRemaining) {
        await _animateAndDeleteExercise(exercise.id, exerciseOrderIndex);
        return;
      }

      await ref
          .read(exercisesAndSetsProvider(widget.workoutSessionId).notifier)
          .removeSetFromExercise(activeSessionSetId);
    }

    final child = Column(
      children: [
        if (setIndexUI > 0) _separator(),
        _dismissibleSet(
          exercise.id,
          exerciseOrderIndex,
          setIdentity,
          activeSessionSetId,
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
                  exercise.id,
                  exercise.orderIndex!,
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
          exercise.id,
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

  Widget _buildHeader(Exercise exercise, double iconSize) {
    return _dismissibleExercise(
      exercise.id,
      exercise.orderIndex!,
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

    await ref
        .read(exercisesAndSetsProvider(widget.workoutSessionId).notifier)
        .deleteExercise(exerciseId, exerciseOrderIndex);

    return false;
  }

  Widget _visualLayer(Exercise exercise) {
    assert(
      exercise.orderIndex != null,
      'Active session exercises must have a non-null orderIndex.',
    );
    final exerciseOrderIndex = exercise.orderIndex!;

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

  List<Widget> _interactivLayer(Exercise exercise, double screenWidth) {
    Future<void> deleteExerciseFromSettings() async {
      await _animateAndDeleteExercise(exercise.id, exercise.orderIndex!);
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
              ExerciseSettings.openExerciseSettings(
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
