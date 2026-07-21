import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/widgets/app_bars/plans_screen/edit_app_bar.dart';
import 'package:lifting_tracker_app/widgets/plans_screen/change_name.dart';
import 'package:lifting_tracker_app/widgets/plans_screen/change_name_flow.dart/change_day_name_flow.dart';

class EditDay extends StatelessWidget {
  const EditDay(this.dayId, {super.key});

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
