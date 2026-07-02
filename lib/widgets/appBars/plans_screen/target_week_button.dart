import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/persisted/week_progress.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class TargetWeekButton extends ConsumerWidget {
  const TargetWeekButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetAsync = ref.watch(weeklyWorkoutProgressProvider);

    return TextButton.icon(
      onPressed: () {},
      icon: Icon(PhosphorIcons.target(), size: 16, color: AppColors.secondary),
      style: TextButton.styleFrom(
        side: BorderSide(color: AppColors.cardBorder),
        backgroundColor: AppColors.onCardTransparent,
      ),
      label: targetAsync.when(
        loading: () => Container(
          width: double.infinity,
          height: double.infinity,
          color: Color.fromARGB(255, 32, 40, 54),
        ),
        error: (_, _) => const Center(child: Text('Error')),
        data: (target) => Text(
          '${target.target.toString()}/wk',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    );
  }
}
