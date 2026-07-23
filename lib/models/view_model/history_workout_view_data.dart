import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/models/view_model/history_month_view_data.dart';

class HistoryWorkoutViewData {
  HistoryWorkoutViewData({
    required this.workoutId,
    required this.workoutName,
    required this.startedAt,
    String? weekdayLabel,
    int? dayOfMonth,
    required int durationSeconds,
    required this.exercisesLabel,
  }) : weekdayLabel = toUpperFirst(DateFormat.E('en_US').format(startedAt)),
       dayOfMonth = startedAt.day,
       durationMinutes = (durationSeconds / 60).round();

  final int workoutId;
  final String workoutName;
  final DateTime startedAt;

  final String weekdayLabel;
  final int dayOfMonth;
  final int durationMinutes;

  final List<String> exercisesLabel;
}
