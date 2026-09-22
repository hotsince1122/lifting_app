import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_data.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/active_session_sets_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/app_settings_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/day_exercises_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/exercises_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/logged_sets_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/split_days_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/split_plans_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/workout_sessions_backup_record.dart';

BackupSnapshot buildBackupSnapshotFixture() {
  return BackupSnapshot(
    backupFormatVersion: BackupSnapshot.currentFormatVersion,
    createdAt: DateTime.parse('2026-09-13T12:30:00+03:00'),
    data: const BackupData(
      splitPlans: [
        SplitPlansBackupRecord(
          id: 7,
          name: 'Push Pull Legs',
          isPreset: 0,
          isActive: 1,
        ),
      ],
      splitDays: [
        SplitDaysBackupRecord(
          id: 'pull-day',
          splitId: 7,
          name: 'Pull',
          orderIdx: 2,
        ),
      ],
      exercises: [
        ExercisesBackupRecord(
          id: 'bicep_curls',
          name: 'Bicep Curls',
          muscleGroup: 'biceps',
        ),
      ],
      dayExercises: [
        DayExercisesBackupRecord(
          id: 15,
          dayId: 'pull-day',
          exerciseId: 'bicep_curls',
          orderIdx: 0,
        ),
      ],
      workoutSessions: [
        WorkoutSessionsBackupRecord(
          id: 21,
          workoutName: 'Pull',
          dayId: 'pull-day',
          startedAt: 1770000000000,
          finishedAt: 1770003600000,
          durationSeconds: 3600,
          cycleIndex: 3,
          status: 'completed',
        ),
        WorkoutSessionsBackupRecord(
          id: 22,
          workoutName: 'Pull',
          dayId: 'pull-day',
          startedAt: 1770086400000,
          finishedAt: null,
          durationSeconds: null,
          cycleIndex: 4,
          status: 'active',
        ),
      ],
      loggedSets: [
        LoggedSetsBackupRecord(
          id: 32,
          exerciseId: 'bicep_curls',
          sessionId: 21,
          weight: 14.5,
          repetitions: 10,
          notes: 'Good set',
          setIndex: 2,
          isWarmup: 0,
          orderIndex: 4,
          exerciseOccurrenceIndex: 1,
        ),
      ],
      activeSessionSets: [
        ActiveSessionSetsBackupRecord(
          id: 41,
          workoutSessionId: 22,
          exerciseId: 'bicep_curls',
          exerciseOrderIndex: 4,
          exerciseOccurrenceIndex: 1,
          setIndex: 2,
          hintWeight: 14.5,
          hintRepetitions: 10,
          hintNotes: 'Controlled eccentric',
          actualWeight: null,
          actualRepetitions: null,
          actualNotes: null,
          isWarmup: 0,
        ),
      ],
      appSettings: AppSettingsBackupRecord(
        id: 1,
        weekStreak: 8,
        workoutsPerWeekTarget: 4,
        weeklyGymAttendance: '1010000',
        weeklyGymAttendanceWeekStart: '2026-09-07',
        didUserFinishSetup: 1,
      ),
    ),
  );
}

Map<String, Object?> buildBackupSnapshotJsonFixture() {
  return {
    'backupFormatVersion': 1,
    'createdAt': '2026-09-13T09:30:00.000Z',
    'data': {
      'split_plans': [
        {'id': 7, 'name': 'Push Pull Legs', 'is_preset': 0, 'is_active': 1},
      ],
      'split_days': [
        {'id': 'pull-day', 'split_id': 7, 'name': 'Pull', 'order_idx': 2},
      ],
      'exercises': [
        {'id': 'bicep_curls', 'name': 'Bicep Curls', 'muscle_group': 'biceps'},
      ],
      'day_exercises': [
        {
          'id': 15,
          'day_id': 'pull-day',
          'exercise_id': 'bicep_curls',
          'order_idx': 0,
        },
      ],
      'workout_sessions': [
        {
          'id': 21,
          'workout_name': 'Pull',
          'day_id': 'pull-day',
          'started_at': 1770000000000,
          'finished_at': 1770003600000,
          'duration_seconds': 3600,
          'cycle_index': 3,
          'status': 'completed',
        },
        {
          'id': 22,
          'workout_name': 'Pull',
          'day_id': 'pull-day',
          'started_at': 1770086400000,
          'finished_at': null,
          'duration_seconds': null,
          'cycle_index': 4,
          'status': 'active',
        },
      ],
      'logged_sets': [
        {
          'id': 32,
          'ex_id': 'bicep_curls',
          'session_id': 21,
          'weight': 14.5,
          'repetitions': 10,
          'notes': 'Good set',
          'set_index': 2,
          'is_warmup': 0,
          'order_index': 4,
          'exercise_occurrence_index': 1,
        },
      ],
      'active_session_sets': [
        {
          'id': 41,
          'workout_session_id': 22,
          'exercise_id': 'bicep_curls',
          'exercise_order_index': 4,
          'exercise_occurrence_index': 1,
          'set_index': 2,
          'hint_weight': 14.5,
          'hint_repetitions': 10,
          'hint_notes': 'Controlled eccentric',
          'actual_weight': null,
          'actual_repetitions': null,
          'actual_notes': null,
          'is_warmup': 0,
        },
      ],
      'app_settings': {
        'id': 1,
        'week_streak': 8,
        'workouts_per_week_target': 4,
        'weekly_gym_attendance': '1010000',
        'weekly_gym_attendance_week_start': '2026-09-07',
        'did_user_finish_setup': 1,
      },
    },
  };
}
