import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/features/history/presentation/widgets/edit_app_bar.dart';
import 'package:lifting_tracker_app/features/plans/presentation/widgets/change_name.dart';
import 'package:lifting_tracker_app/features/workouts/presentation/editor/change_name_flow.dart/change_day_name_flow.dart';

class EditDayPage extends StatelessWidget {
  const EditDayPage(this.dayId, {super.key});

  final String dayId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EditAppBar('Edit day'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, bottom: 32),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChangeName(
                    flow: ChangeDayNameFlow(dayId: dayId),
                    key: ValueKey(dayId),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
