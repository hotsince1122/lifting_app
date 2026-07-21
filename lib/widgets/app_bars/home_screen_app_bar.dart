import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/providers/persisted/week_streak.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';

import 'package:lifting_tracker_app/widgets/app_bars/app_bar_settings.dart';
import 'package:lifting_tracker_app/widgets/app_bars/screen_app_bar.dart';


class HomeScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeScreenAppBar({super.key});

  @override
  Size get preferredSize => appBarHeight;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final String monthLabel = DateFormat('MMMM', 'en_US').format(now);
    final String weekdayLabel = DateFormat('EEEE', 'en_US').format(now);

    // final Widget streakWidget = GradientCard(
    //   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    //   gradientVariant: AppGradients.card,
    //   child: Row(
    //     children: [
    //       Image.asset('assets/fire.png', height: 16, width: 16),
    //       const SizedBox(width: 8),
    //       _StreakWeekAsync(),
    //     ],
    //   ),
    // );

    final Widget streakWidget = Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: TextButton.icon(
          onPressed: () {},
          icon: Image.asset('assets/fire.png', height: 16, width: 16),
          style: TextButton.styleFrom(
            side: BorderSide(color: AppColors.cardBorder),
            backgroundColor: AppColors.onCardTransparent,
          ),
          label: _StreakWeekAsync(),
        ),
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
