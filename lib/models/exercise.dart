import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Exercise {
  Exercise({required this.name, required this.muscleGroup, String? id})
    : id = id ?? uuid.v4();

  final String id;
  final String name;
  final String muscleGroup;
}