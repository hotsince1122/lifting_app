import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/models/view_model/history_workout_vm.dart';

String toUpperFirst(String label) {
  if (label.isEmpty) return label;
  return label[0].toUpperCase() + label.substring(1);
}

class HistoryMonthVm {
  HistoryMonthVm({
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
  final List<HistoryWorkoutVm> workouts;
}
