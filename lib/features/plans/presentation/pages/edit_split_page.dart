import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/features/plans/application/split_days_controller.dart';
import 'package:lifting_tracker_app/core/ui/app_bars/simple_app_bar.dart';
import 'package:lifting_tracker_app/features/plans/presentation/widgets/add_to_split.dart';
import 'package:lifting_tracker_app/features/plans/presentation/widgets/change_name.dart';
import 'package:lifting_tracker_app/features/plans/presentation/editor/change_name_flow/change_split_name_flow.dart';
import 'package:lifting_tracker_app/features/plans/presentation/widgets/training_days.dart';

class EditSplitPage extends ConsumerWidget {
  const EditSplitPage(this.splitId, {super.key});

  final int splitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: SimpleAppBar('Edit split', isTitleCentered: true),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.s16,
              right: AppSpacing.s16,
              bottom: AppSpacing.s32,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChangeName(
                    flow: ChangeSplitNameFlow(splitId: splitId),
                    key: ValueKey(splitId),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  TrainingDays(splitId),
                  const SizedBox(height: AppSpacing.s16),
                  AddToSplit(
                    buttonLabel: 'Add day',
                    addFunction: () => ref
                        .read(splitDaysProvider(splitId).notifier)
                        .createNewDay(),
                  ),
                  const SizedBox(height: AppSpacing.s48),
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
