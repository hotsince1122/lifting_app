import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_record_reader.dart';

final class AppSettingsBackupRecord {
  const AppSettingsBackupRecord({
    required this.id,
    required this.weekStreak,
    required this.workoutsPerWeekTarget,
    required this.weeklyGymAttendance,
    required this.weeklyGymAttendanceWeekStart,
    required this.didUserFinishSetup,
  });

  final int id;
  final int? weekStreak;
  final int? workoutsPerWeekTarget;
  final String? weeklyGymAttendance;
  final String? weeklyGymAttendanceWeekStart;
  final int didUserFinishSetup;

  factory AppSettingsBackupRecord.fromDatabaseRow(
    Map<String, Object?> row,
    String path,
  ) {
    final reader = BackupRecordReader(row, path: path);

    return AppSettingsBackupRecord(
      id: reader.requiredInt('id'),
      weekStreak: reader.nullableInt('week_streak'),
      workoutsPerWeekTarget: reader.nullableInt('workouts_per_week_target'),
      weeklyGymAttendance: reader.nullableString('weekly_gym_attendance'),
      weeklyGymAttendanceWeekStart: reader.nullableString(
        'weekly_gym_attendance_week_start',
      ),
      didUserFinishSetup: reader.requiredSqlBoolean('did_user_finish_setup'),
    );
  }

  factory AppSettingsBackupRecord.fromJson(
    Map<String, Object?> json,
    String path,
  ) {
    return AppSettingsBackupRecord.fromDatabaseRow(json, path);
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'week_streak': weekStreak,
      'workouts_per_week_target': workoutsPerWeekTarget,
      'weekly_gym_attendance': weeklyGymAttendance,
      'weekly_gym_attendance_week_start': weeklyGymAttendanceWeekStart,
      'did_user_finish_setup': didUserFinishSetup,
    };
  }
}
