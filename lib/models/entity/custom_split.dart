import 'package:lifting_tracker_app/models/entity/split_day.dart';

class CustomSplit {
  const CustomSplit(this.splitName, this.splitDays);

  final String splitName;
  final List<SplitDay> splitDays;
}