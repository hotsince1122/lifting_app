import 'package:lifting_tracker_app/models/entity/training_set.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();
const _copyWithSentinel = Object();

class Exercise {
  Exercise({
    required this.name,
    required this.muscleGroup,
    List<TrainingSet>? sets,
    String? id,
    this.orderIndex,
    this.note,
    this.idInDayExerciseRelation,
  }) : id = id ?? uuid.v4(),
       sets = sets ?? [];

  final String id;
  final String name;
  final String muscleGroup;
  final List<TrainingSet> sets;
  final int? orderIndex;
  final String? note;

  final int? idInDayExerciseRelation;

  Exercise copyWith({
    String? id,
    String? name,
    String? muscleGroup,
    List<TrainingSet>? sets,
    Object? orderIndex = _copyWithSentinel,
    Object? note = _copyWithSentinel,
    Object? idInDayExerciseRelation = _copyWithSentinel,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      sets: sets ?? this.sets,
      orderIndex: identical(orderIndex, _copyWithSentinel)
          ? this.orderIndex
          : orderIndex as int?,
      note: identical(note, _copyWithSentinel) ? this.note : note as String?,
      idInDayExerciseRelation:
          identical(idInDayExerciseRelation, _copyWithSentinel)
          ? this.idInDayExerciseRelation
          : idInDayExerciseRelation as int?,
    );
  }
}
