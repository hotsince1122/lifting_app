import 'package:lifting_tracker_app/features/exercises/domain/catalog_exercise.dart';

class PlannedExercise {
  const PlannedExercise({
    required this.catalogExercise,
    required this.relationId,
    required this.orderIndex,
  });

  final CatalogExercise catalogExercise;
  final int relationId;
  final int orderIndex;

  PlannedExercise copyWith({
    CatalogExercise? catalogExercise,
    int? relationId,
    int? orderIndex,
  }) {
    return PlannedExercise(
      catalogExercise: catalogExercise ?? this.catalogExercise,
      relationId: relationId ?? this.relationId,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
