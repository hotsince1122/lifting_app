import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/widgets/app_bars/plans_screen/edit_app_bar.dart';
import 'package:lifting_tracker_app/widgets/plans_screen/add_day_to_split.dart';
import 'package:lifting_tracker_app/widgets/plans_screen/change_name.dart';
import 'package:lifting_tracker_app/widgets/plans_screen/change_name_flow.dart/change_split_name_flow.dart';
import 'package:lifting_tracker_app/widgets/plans_screen/training_days.dart';

class EditSplit extends StatelessWidget {
  const EditSplit(this.splitId, {super.key});

  final int splitId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EditAppBar('Edit split'),
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
                    flow: ChangeSplitNameFlow(splitId: splitId),
                    key: ValueKey(splitId),
                  ),
                  const SizedBox(height: 24),
                  TrainingDays(splitId),
                  const SizedBox(height: 18),
                  AddDayToSplit(splitId),
                  const SizedBox(height: 48),
                  Center(
                    child: Text(
                      'Activate another split to delete',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Colors.red.withAlpha(80),
                      ),
                    ),
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
