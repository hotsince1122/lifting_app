import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';

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
      gradient: Gradients.of(AppGradients.darkOne),
    ),
    PresetSplitConfig(
      key: 'UL',
      title: 'UL',
      subtitle: 'Upper / Lower',
      nrOfDays: '2-day cycle',
      gradient: Gradients.of(AppGradients.darkThree),
    ),
    PresetSplitConfig(
      key: 'Arnold',
      title: 'Arnold',
      subtitle: 'Chest & Back / Shoulders & Arms / Legs',
      nrOfDays: '3-day cycle',
      gradient: Gradients.of(AppGradients.darkTwo),
    ),
    PresetSplitConfig(
      key: 'FB',
      title: 'FB (Full Body)',
      subtitle: 'Day1 / Day2 / Day3',
      nrOfDays: '3-day cycle',
      gradient: Gradients.of(AppGradients.darkThree),
    ),
  ];
}
