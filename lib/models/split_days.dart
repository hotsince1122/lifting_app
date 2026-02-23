import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/models/gradient_variants.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class SplitDay {
  SplitDay({required this.name, required this.orderIndex, String? id, this.selectedPreset})
    : id = id ?? uuid.v4();

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
      SplitDay(name: 'Shoulders & Arms', orderIndex: 1, selectedPreset: 'Arnold'),
      SplitDay(name: 'Legs', orderIndex: 2, selectedPreset: 'Arnold'),
    ],
    "FB": [
      SplitDay(name: 'Day1', orderIndex: 0, selectedPreset: 'FB'),
      SplitDay(name: 'Day2', orderIndex: 1, selectedPreset: 'FB'),
      SplitDay(name: 'Day3', orderIndex: 2, selectedPreset: 'FB'),
    ],
  };
}

class PresetSplitConfig {
  const PresetSplitConfig({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.nrOfDays,
    required this.gradient,
  });

  final String key;
  final String title;
  final String subtitle;
  final String nrOfDays;
  final LinearGradient gradient;

  static List<PresetSplitConfig> presetConfigs = [
  PresetSplitConfig(
    key: 'PPL',
    title: 'PPL',
    subtitle: 'Push / Pull / Legs',
    nrOfDays: '3-day cycle',
    gradient: Gradients.of(GradientVariant.darkOne),
  ),
  PresetSplitConfig(
    key: 'UL',
    title: 'UL',
    subtitle: 'Upper / Lower',
    nrOfDays: '2-day cycle',
    gradient: Gradients.of(GradientVariant.darkThree),
  ),
  PresetSplitConfig(
    key: 'Arnold',
    title: 'Arnold',
    subtitle: 'Chest & Back / Shoulders & Arms / Legs',
    nrOfDays: '3-day cycle',
    gradient: Gradients.of(GradientVariant.darkTwo),
  ),
  PresetSplitConfig(
    key: 'FB',
    title: 'FB (Full Body)',
    subtitle: 'Day1 / Day2 / Day3',
    nrOfDays: '3-day cycle',
    gradient: Gradients.of(GradientVariant.darkThree),
  ),
];
}