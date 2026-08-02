import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/card_flow/workout_focus_card_flow.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/widgets/home_summary_card.dart';

class WorkoutFocusSection extends StatelessWidget {
  const WorkoutFocusSection({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeSummaryCard(flow: WorkoutFocusCardFlow());
  }
}
