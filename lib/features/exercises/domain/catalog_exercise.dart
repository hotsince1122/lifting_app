import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class CatalogExercise {
  CatalogExercise({required this.name, required this.muscleGroup, String? id})
    : id = id ?? _uuid.v4();

  final String id;
  final String name;
  final String muscleGroup;

  CatalogExercise copyWith({String? id, String? name, String? muscleGroup}) {
    return CatalogExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
    );
  }
}
