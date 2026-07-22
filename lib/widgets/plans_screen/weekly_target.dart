import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/presentation/plans_change_weekly_target_mode.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/ui/cards/solid_card.dart';
import 'package:lifting_tracker_app/widgets/profile_setup/workouts_per_week_slider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class WeeklyTarget extends ConsumerWidget {
  const WeeklyTarget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget title = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(PhosphorIcons.target(), size: 16, color: AppColors.secondary),
        const SizedBox(width: 4),
        Text('Weekly target', style: Theme.of(context).textTheme.titleMedium),
      ],
    );

    final Widget subtitle = Text(
      'Days per week you aim to train.',
      style: Theme.of(
        context,
      ).textTheme.bodyMedium!.copyWith(color: AppColors.onSurfaceMuted),
    );

    final isNotEnabled = ref.watch(changeWeeklyTargetMode);

    return ClipRect(
      child: AnimatedAlign(
        alignment: Alignment.topCenter,
        heightFactor: isNotEnabled ? 0 : 1.0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
        child: AnimatedOpacity(
          opacity: isNotEnabled ? 0 : 1.0,
          duration: const Duration(milliseconds: 280),
          child: Column(
            children: [
              SolidCard(
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      title,
                      subtitle,
                      const SizedBox(height: 16),
                      WorkoutsPerWeekSlider(),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ), //so the card shadow is visiable + space between widgets
            ],
          ),
        ),
      ),
    );
  }
}
