import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/features/history/presentation/view_data/history_workout_view_data.dart';

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
