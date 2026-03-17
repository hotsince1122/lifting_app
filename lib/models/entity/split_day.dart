import 'package:uuid/uuid.dart';

const uuid = Uuid();

class SplitDay {
  SplitDay({
    required this.name,
    required this.orderIndex,
    String? id,
  }) : id = id ?? uuid.v4();

  final String id;
  final String name;
  final int orderIndex;
}
