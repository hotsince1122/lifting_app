import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/models/view_model/history_workout_view_data.dart';
import 'package:lifting_tracker_app/providers/persisted/history_workout_actions.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/pages/workout_editor_page.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/history_screen/date_of_workout_icon.dart';
import 'package:lifting_tracker_app/widgets/history_screen/history_month_card.dart';

class HistoryWorkoutLayout extends ConsumerStatefulWidget {
  const HistoryWorkoutLayout(
    this.workoutData,
    this.isEditingMode,
    this.position, {
    super.key,
  });

  final HistoryWorkoutViewData workoutData;
  final bool isEditingMode;
  final WorkoutPositionInLayout position;

  @override
  ConsumerState<HistoryWorkoutLayout> createState() =>
      HistoryWorkoutLayoutState();
}

class HistoryWorkoutLayoutState extends ConsumerState<HistoryWorkoutLayout> {
  bool isDeleting = false;
  bool isPreparingEdit = false;
  static const deletionCollapseDuration = Duration(milliseconds: 90);

  static const deletionIconPopDuration = Duration(milliseconds: 120);
  static const editingCollapseDuration = Duration(milliseconds: 180);

  static const marginPadding = SizedBox(height: 18);
  static const betweenPadding = SizedBox(height: 12);

  void animateDeletion(
    HistoryWorkoutActionsNotifier historyWorkoutActionsProvider,
  ) async {
    if (isDeleting) return;

    if (!(await confirmDeletion())) return;

    setState(() {
      isDeleting = true;
    });

    await Future.delayed(deletionCollapseDuration);

    if (!mounted) return;

    final didSucceed = await historyWorkoutActionsProvider.deleteWorkout(
      widget.workoutData.workoutId,
    );

    if (!didSucceed && mounted) {
      await showDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('An error has occured!'),
          content: Text('The deletion has been rollbacked.'),
          actions: [
            CupertinoDialogAction(
              onPressed: Navigator.of(context).pop,
              child: Text('Ok'),
            ),
          ],
        ),
      );

      if (mounted) {
        setState(() {
          isDeleting = false;
        });
      }
    }
  }

  Future<void> openEditor(
    HistoryWorkoutActionsNotifier historyWorkoutActionsProvider,
  ) async {
    if (isPreparingEdit || isDeleting) return;

    setState(() {
      isPreparingEdit = true;
    });

    final didPrepare = await historyWorkoutActionsProvider
        .clearActiveSessionSets(widget.workoutData.workoutId);

    if (!mounted) return;

    setState(() {
      isPreparingEdit = false;
    });

    if (!didPrepare) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not open this workout. Please try again.'),
          ),
        );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            WorkoutEditorPage.edit(widget.workoutData.workoutId),
      ),
    );
  }

  Future<bool> confirmDeletion() async {
    late bool confirm;

    await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Are you sure ?'),
        content: Text(
          'Deletion of a workout cannot be undone. Deleting this workout can affect your week progress.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              confirm = true;
              Navigator.of(context).pop();
            },
            child: Text('Confirm'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              confirm = false;
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );

    return confirm;
  }

  Widget padContent(WorkoutPositionInLayout position, Widget child) {
    return Column(
      children: [
        ...switch (position) {
          WorkoutPositionInLayout.first => [
            marginPadding,
            child,
            betweenPadding,
          ],

          WorkoutPositionInLayout.last => [
            betweenPadding,
            child,
            marginPadding,
          ],

          WorkoutPositionInLayout.between => [
            betweenPadding,
            child,
            betweenPadding,
          ],

          WorkoutPositionInLayout.only => [marginPadding, child, marginPadding],
        },
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyWorkoutActionsNotifier = ref.read(
      historyWorkoutActionsProvider.notifier,
    );

    final isEditingMode = widget.isEditingMode;
    final workoutData = widget.workoutData;

    return GestureDetector(
      onTap: () => openEditor(historyWorkoutActionsNotifier),
      child: ClipRect(
        child: AnimatedAlign(
          duration: deletionCollapseDuration,
          curve: Curves.fastOutSlowIn,
          alignment: Alignment.topCenter,
          heightFactor: !isDeleting ? 1.0 : 0.0,
          child: padContent(
            widget.position,
            LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = isEditingMode
                    ? constraints.maxWidth * 0.84
                    : constraints.maxWidth;
                const dateIconWidth = 56.0;
                const contentGap = 12.0;
                const durationWidth = 56.0;
                final availableTitleWidth =
                    contentWidth - dateIconWidth - contentGap - durationWidth;
                final titleWidth = availableTitleWidth > 0
                    ? availableTitleWidth
                    : 0.0;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 6,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: AnimatedScale(
                          scale: isEditingMode ? 1 : 0,
                          duration: deletionIconPopDuration,
                          curve: Curves.easeOutBack,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            onTap: isEditingMode && !isDeleting
                                ? () => animateDeletion(
                                    historyWorkoutActionsNotifier,
                                  )
                                : null,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.remove_rounded,
                                  color: AppColors.onSurface,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedAlign(
                      alignment: isEditingMode
                          ? Alignment.centerRight
                          : Alignment.center,
                      duration: editingCollapseDuration,
                      curve: Curves.easeOutCubic,
                      child: AnimatedContainer(
                        width: contentWidth,
                        duration: editingCollapseDuration,
                        curve: Curves.easeOutCubic,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DateOfWorkoutIcon(
                              weekday: workoutData.weekdayLabel,
                              calendarDay: workoutData.dayOfMonth,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    width: titleWidth,
                                    child: Text(
                                      workoutData.workoutName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge!
                                          .copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (workoutData.exercisesLabel.isEmpty)
                                        Text(
                                          'No exercises logged.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(
                                                color: AppColors.onSurfaceMuted,
                                              ),
                                        ),
                                      for (final exerciseLabel
                                          in workoutData.exercisesLabel)
                                        Text(exerciseLabel),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: SizedBox(
                        width: durationWidth,
                        child: Text(
                          '${workoutData.durationMinutes} min',
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.titleSmall!
                              .copyWith(color: AppColors.onSurfaceMuted),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
