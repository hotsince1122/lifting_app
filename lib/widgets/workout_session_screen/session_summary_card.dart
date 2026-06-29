import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/providers/persisted/workout_name.dart';
import 'package:lifting_tracker_app/providers/presentation/workout_header_summary_card.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/widgets/appBars/workout_session/workout_editor_flow.dart';
import 'package:lifting_tracker_app/widgets/core/gradient_cards.dart';

class SessionSummaryCard extends ConsumerStatefulWidget {
  const SessionSummaryCard(this.flow, {required this.sessionId, super.key});

  final int sessionId;
  final WorkoutEditorFlow flow;

  @override
  ConsumerState<SessionSummaryCard> createState() => _SessionSummaryCardState();
}

class _SessionSummaryCardState extends ConsumerState<SessionSummaryCard> {
  TextEditingController? _workoutNameController;

  @override
  void dispose() {
    _workoutNameController?.dispose();
    super.dispose();
  }

  void _syncWorkoutNameController(String workoutName) {
    final controller = _workoutNameController;

    if (controller == null) {
      _workoutNameController = TextEditingController(text: workoutName);
      return;
    }

    if (controller.text == workoutName) return;

    controller.value = TextEditingValue(
      text: workoutName,
      selection: TextSelection.collapsed(offset: workoutName.length),
    );
  }

  void _handleWorkoutNameChanged(String newName) {
    unawaited(
      widget.flow.onWorkoutNameChange(ref, widget.sessionId, newName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionSummaryCardAsync = ref.watch(
      workoutHeaderSummaryCardProvider(widget.sessionId),
    );
    final workoutNameAsync = ref.watch(workoutNameProvider(widget.sessionId));

    String transformIntoDateLabel(DateTime? date) {
      if (date == null) return '-';

      final weekday = DateFormat('EEE', 'en_US').format(date);
      final month = DateFormat('MMM', 'en_US').format(date);
      final day = date.day;

      final hour = date.hour;
      final minute = date.minute;
      final time =
          '${hour < 10 ? '0$hour' : hour}:${minute < 10 ? '0$minute' : minute}';

      return '$weekday, $day $month at $time';
    }

    Widget infoTile(String title, String description) {
      return Row(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: AppColors.primary,
              letterSpacing: 0.1,
            ),
          ),
        ],
      );
    }

    Widget workoutName(TextEditingController controller) {
      return TextField(
        controller: controller,
        onChanged: _handleWorkoutNameChanged,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        maxLines: 2,
        minLines: 1,
        decoration: InputDecoration(
          hintText: 'Workout name',
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
          hintStyle: Theme.of(context).textTheme.headlineSmall!.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.onSurfaceMuted,
          ),
        ),
        style: Theme.of(
          context,
        ).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w900),
      );
    }

    if (sessionSummaryCardAsync.isLoading || workoutNameAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sessionSummaryCardAsync.hasError || workoutNameAsync.hasError) {
      return const Center(child: Text('An error has occured! Try again.'));
    }

    final sessionSummaryCard = sessionSummaryCardAsync.requireValue;
    final currentWorkoutName = workoutNameAsync.requireValue;

    if (sessionSummaryCard == null) {
      return const Center(child: Text('Could not load this workout.'));
    }

    _syncWorkoutNameController(currentWorkoutName);
    final workoutNameController = _workoutNameController!;

    final startTimeLabel = transformIntoDateLabel(sessionSummaryCard.startTime);
    final endTimeLabel = transformIntoDateLabel(sessionSummaryCard.endTime);

    String durationInMinutes = (sessionSummaryCard.workoutDurationInMinutes)
        .toString();
    if (durationInMinutes == 'null') {
      durationInMinutes = '-';
    } else {
      durationInMinutes += ' min';
    }

    return AspectRatio(
      aspectRatio: 1.55,
      child: GradientCard(
        gradientVariant: AppGradients.card,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:
              [
                    workoutName(workoutNameController),
                    infoTile('Start Time', startTimeLabel),
                    infoTile('End Time', endTimeLabel),
                    infoTile('Duration', durationInMinutes),
                  ]
                  .expand(
                    (item) => [
                      item,
                      const Divider(height: 1, color: AppColors.cardBorder),
                    ],
                  )
                  .toList()
                ..removeLast(),
        ),
      ),
    );
  }
}
