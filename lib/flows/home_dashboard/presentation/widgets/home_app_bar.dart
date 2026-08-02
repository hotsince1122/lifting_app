import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/features/progress/application/week_streak_controller.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';

import 'package:lifting_tracker_app/core/ui/app_bars/app_bar_settings.dart';
import 'package:lifting_tracker_app/core/ui/app_bars/screen_app_bar.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => appBarHeight;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final String monthLabel = DateFormat('MMMM', 'en_US').format(now);
    final String weekdayLabel = DateFormat('EEEE', 'en_US').format(now);

    final Widget streakWidget = Material(
      color: Colors.transparent,

      child: TextButton.icon(
        onPressed: () {},
        icon: Image.asset(
          'assets/fire.png',
          height: AppSpacing.s16,
          width: AppSpacing.s16,
        ),
        style: TextButton.styleFrom(
          side: BorderSide(color: AppColors.cardBorder),
          backgroundColor: AppColors.onCardTransparent,
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
        ),
        label: _StreakWeekAsync(),
      ),
    );

    return ScreenAppBar(
      title: weekdayLabel,
      subtitle: '$monthLabel ${now.day},',
      trailing: streakWidget,
    );
  }
}

class _StreakWeekAsync extends ConsumerWidget {
  const _StreakWeekAsync();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStreakAsync = ref.watch(weekStreakProvider);

    return weekStreakAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Error!')),
      data: (weekStreak) {
        return Text(
          weekStreak.toString(),
          style: Theme.of(context).textTheme.titleSmall,
        );
      },
    );
  }
}
