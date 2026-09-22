import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_format_exception.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/backup_snapshot.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/active_session_sets_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/day_exercises_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/exercises_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/logged_sets_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/split_days_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/split_plans_backup_record.dart';
import 'package:lifting_tracker_app/features/cloud_backup/domain/table_records/workout_sessions_backup_record.dart';

void validateBackupSnapshot(BackupSnapshot snapshot) {
  if (snapshot.data.appSettings.id != 1) {
    throw BackupFormatException(
      code: BackupFormatErrorCode.invalidValue,
      path: r'$.data.app_settings.id',
      message: 'App settings id is not 1.',
    );
  }

  final splitPlanIds =
      _returnAndCheckIdsForDuplicates<int, SplitPlansBackupRecord>(
        snapshot.data.splitPlans,
        (record) => record.id,
        path: r'$.data.split_plans',
      );

  final splitDaysIds =
      _returnAndCheckIdsForDuplicates<String, SplitDaysBackupRecord>(
        snapshot.data.splitDays,
        (record) => record.id,
        path: r'$.data.split_days',
      );

  final exerciseIds =
      _returnAndCheckIdsForDuplicates<String, ExercisesBackupRecord>(
        snapshot.data.exercises,
        (record) => record.id,
        path: r'$.data.exercises',
      );

  _returnAndCheckIdsForDuplicates<int, DayExercisesBackupRecord>(
    snapshot.data.dayExercises,
    (record) => record.id,
    path: r'$.data.day_exercises',
  );

  final workoutSessionIds =
      _returnAndCheckIdsForDuplicates<int, WorkoutSessionsBackupRecord>(
        snapshot.data.workoutSessions,
        (record) => record.id,
        path: r'$.data.workout_sessions',
      );

  _returnAndCheckIdsForDuplicates<int, LoggedSetsBackupRecord>(
    snapshot.data.loggedSets,
    (record) => record.id,
    path: r'$.data.logged_sets',
  );

  _returnAndCheckIdsForDuplicates<int, ActiveSessionSetsBackupRecord>(
    snapshot.data.activeSessionSets,
    (record) => record.id,
    path: r'$.data.active_session_sets',
  );

  final splitDaysIdsReferencedFromSplitDays =
      _returnAColumn<int, SplitDaysBackupRecord>(
        snapshot.data.splitDays,
        (record) => record.splitId,
      );

  _validateReferences(
    referencedIds: splitDaysIdsReferencedFromSplitDays,
    validIds: splitPlanIds,
    path: r'$.data.split_days',
    referenceField: 'split_id',
  );

  final dayIdsReferencedFromDayExercises =
      _returnAColumn<String, DayExercisesBackupRecord>(
        snapshot.data.dayExercises,
        (record) => record.dayId,
      );

  _validateReferences(
    referencedIds: dayIdsReferencedFromDayExercises,
    validIds: splitDaysIds,
    path: r'$.data.day_exercises',
    referenceField: 'day_id',
  );

  final exercisesIdsReferencesFromDayExercises =
      _returnAColumn<String, DayExercisesBackupRecord>(
        snapshot.data.dayExercises,
        (record) => record.exerciseId,
      );

  _validateReferences(
    referencedIds: exercisesIdsReferencesFromDayExercises,
    validIds: exerciseIds,
    path: r'$.data.day_exercises',
    referenceField: 'exercise_id',
  );

  const workoutSessionsPath = r'$.data.workout_sessions';

  for (var index = 0; index < snapshot.data.workoutSessions.length; index++) {
    final dayId = snapshot.data.workoutSessions[index].dayId;

    if (dayId == null) {
      continue;
    }

    if (!splitDaysIds.contains(dayId)) {
      throw BackupFormatException(
        code: BackupFormatErrorCode.invalidReference,
        path: '$workoutSessionsPath[$index].day_id',
        message: 'Missing referenced id.',
      );
    }
  }

  final sessionIdsReferencedFromLoggedSets =
      _returnAColumn<int, LoggedSetsBackupRecord>(
        snapshot.data.loggedSets,
        (record) => record.sessionId,
      );

  _validateReferences(
    referencedIds: sessionIdsReferencedFromLoggedSets,
    validIds: workoutSessionIds,
    path: r'$.data.logged_sets',
    referenceField: 'session_id',
  );

  final exerciseIdsReferencedFromLoggedSets =
      _returnAColumn<String, LoggedSetsBackupRecord>(
        snapshot.data.loggedSets,
        (record) => record.exerciseId,
      );

  _validateReferences(
    referencedIds: exerciseIdsReferencedFromLoggedSets,
    validIds: exerciseIds,
    path: r'$.data.logged_sets',
    referenceField: 'ex_id',
  );

  final sessionIdsReferencedFromActiveSessionSets =
      _returnAColumn<int, ActiveSessionSetsBackupRecord>(
        snapshot.data.activeSessionSets,
        (record) => record.workoutSessionId,
      );

  _validateReferences(
    referencedIds: sessionIdsReferencedFromActiveSessionSets,
    validIds: workoutSessionIds,
    path: r'$.data.active_session_sets',
    referenceField: 'workout_session_id',
  );

  final exerciseIdsReferencedFromActiveSessionSets =
      _returnAColumn<String, ActiveSessionSetsBackupRecord>(
        snapshot.data.activeSessionSets,
        (record) => record.exerciseId,
      );

  _validateReferences(
    referencedIds: exerciseIdsReferencedFromActiveSessionSets,
    validIds: exerciseIds,
    path: r'$.data.active_session_sets',
    referenceField: 'exercise_id',
  );
}

Set<Tout> _returnAndCheckIdsForDuplicates<Tout, Tin>(
  List<Tin> records,
  Tout Function(Tin) getId, {
  required String path,
}) {
  final ids = <Tout>{};

  for (var index = 0; index < records.length; index++) {
    if (!(ids.add(getId(records[index])))) {
      throw BackupFormatException(
        code: BackupFormatErrorCode.duplicateId,
        path: '$path[$index].id',
        message: 'Duplicate id.',
      );
    }
  }

  return ids;
}

List<Tout> _returnAColumn<Tout, Tin>(
  List<Tin> records,
  Tout Function(Tin) getValue,
) {
  final column = <Tout>[];

  for (var index = 0; index < records.length; index++) {
    column.add(getValue(records[index]));
  }

  return column;
}

void _validateReferences<Tin>({
  required List<Tin> referencedIds,
  required Set<Tin> validIds,
  required String path,
  required String referenceField,
}) {
  for (var index = 0; index < referencedIds.length; index++) {
    if (!validIds.contains(referencedIds[index])) {
      throw BackupFormatException(
        code: BackupFormatErrorCode.invalidReference,
        path: '$path[$index].$referenceField',
        message: 'Missing referenced id.',
      );
    }
  }
}
