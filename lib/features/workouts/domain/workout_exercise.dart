import 'package:lifting_tracker_app/features/exercises/domain/catalog_exercise.dart';
import 'package:lifting_tracker_app/features/workouts/domain/training_set.dart';

const _copyWithSentinel = Object();

class WorkoutExercise {
  const WorkoutExercise({
    required this.catalogExercise,
    required this.sets,
    required this.orderIndex,
    this.note,
  });

  final CatalogExercise catalogExercise;
  final List<TrainingSet> sets;
  final int orderIndex;
  final String? note;

  WorkoutExercise copyWith({
    CatalogExercise? catalogExercise,
    List<TrainingSet>? sets,
    int? orderIndex,
    Object? note = _copyWithSentinel,
  }) {
    return WorkoutExercise(
      catalogExercise: catalogExercise ?? this.catalogExercise,
      sets: sets ?? this.sets,
      orderIndex: orderIndex ?? this.orderIndex,
      note: identical(note, _copyWithSentinel) ? this.note : note as String?,
    );
  }
}
