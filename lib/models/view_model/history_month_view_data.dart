import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/models/view_model/history_workout_view_data.dart';

String toUpperFirst(String label) {
  if (label.isEmpty) return label;
  return label[0].toUpperCase() + label.substring(1);
}

class HistoryMonthViewData {
  HistoryMonthViewData({
    required this.year,
    required this.month,
    String? label,
    required this.workoutCount,
    required this.workouts,
  }) : label = label ?? DateFormat.yMMMM('en_US').format(DateTime(year, month));

  final int year;
  final int month;
  final String label;
  final int workoutCount;
  final List<HistoryWorkoutViewData> workouts;
}
