import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/features/plans/presentation/widgets/active_plan_overview.dart';
import 'package:lifting_tracker_app/features/plans/presentation/widgets/custom_split_button.dart';
import 'package:lifting_tracker_app/features/progress/presentation/widgets/weekly_target.dart';
import 'package:lifting_tracker_app/features/plans/presentation/widgets/your_plans.dart';

class PlansPage extends StatelessWidget {
  const PlansPage({super.key});

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
