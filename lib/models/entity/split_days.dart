import 'package:uuid/uuid.dart';

const uuid = Uuid();

class SplitDay {
  SplitDay({
    required this.name,
    required this.orderIndex,
    String? id,
    this.selectedPreset,
  }) : id = id ?? uuid.v4();

  final String id;
  final String name;
  final int orderIndex;
  final String? selectedPreset;

  static Map<String, List<SplitDay>> presetSplits = {
    "PPL": [
      SplitDay(name: 'Push', orderIndex: 0, selectedPreset: 'PPL'),
      SplitDay(name: 'Pull', orderIndex: 1, selectedPreset: 'PPL'),
      SplitDay(name: 'Legs', orderIndex: 2, selectedPreset: 'PPL'),
    ],
    "UL": [
      SplitDay(name: 'Upper', orderIndex: 0, selectedPreset: 'UL'),
      SplitDay(name: 'Lower', orderIndex: 1, selectedPreset: 'UL'),
    ],
    "Arnold": [
      SplitDay(name: 'Chest & Back', orderIndex: 0, selectedPreset: 'Arnold'),
      SplitDay(
        name: 'Shoulders & Arms',
        orderIndex: 1,
        selectedPreset: 'Arnold',
      ),
      SplitDay(name: 'Legs', orderIndex: 2, selectedPreset: 'Arnold'),
    ],
    "FB": [
      SplitDay(name: 'Day1', orderIndex: 0, selectedPreset: 'FB'),
      SplitDay(name: 'Day2', orderIndex: 1, selectedPreset: 'FB'),
      SplitDay(name: 'Day3', orderIndex: 2, selectedPreset: 'FB'),
    ],
  };
}
