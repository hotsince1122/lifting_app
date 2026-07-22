import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/widgets/plans_screen/active_plan_overview.dart';
import 'package:lifting_tracker_app/widgets/plans_screen/custom_split_button.dart';
import 'package:lifting_tracker_app/widgets/plans_screen/weekly_target.dart';
import 'package:lifting_tracker_app/widgets/plans_screen/your_plans.dart';

class Plans extends StatelessWidget {
  const Plans({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            WeeklyTarget(),
            ActivePlanOverview(),
            const SizedBox(height: 24),
            YourPlans(),
            const SizedBox(height: 8),
            CustomSplitButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
