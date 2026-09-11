import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/features/authentication/presentation/pages/account_and_backup_page.dart';
import 'package:lifting_tracker_app/features/progress/application/week_streak_controller.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';

import 'package:lifting_tracker_app/core/ui/app_bars/app_bar_settings.dart';
import 'package:lifting_tracker_app/core/ui/app_bars/screen_app_bar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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

    final Widget profileSettingsWidget = IconButton(
      onPressed: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => AccountAndBackupPage()));
      },
      icon: Icon(PhosphorIcons.user(), size: 16, color: AppColors.primary),
      style: IconButton.styleFrom(
        side: BorderSide(color: AppColors.cardBorder),
        backgroundColor: AppColors.onCardTransparent,
      ),
    );

    return ScreenAppBar(
      title: weekdayLabel,
      subtitle: '$monthLabel ${now.day},',
      trailing: Row(
        children: [
          streakWidget,
          const SizedBox(width: AppSpacing.s4),
          profileSettingsWidget,
        ],
      ),
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
