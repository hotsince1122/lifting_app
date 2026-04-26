import 'package:lifting_tracker_app/models/entity/training_set.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Exercise {
  Exercise({
    required this.name,
    required this.muscleGroup,
    List<TrainingSet>? sets,
    String? id,
    this.orderIndex,
    this.note,
    this.idInDayExerciseRelation,
  }) : id = id ?? uuid.v4(), sets = sets ?? [];

  final String id;
  final String name;
  final String muscleGroup;
  final List<TrainingSet> sets;
  final int? orderIndex;
  final String? note;

  final int? idInDayExerciseRelation;
}
