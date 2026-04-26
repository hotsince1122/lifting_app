import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/providers/persisted/week_streak.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/widgets/gradient_cards.dart';

class HomeScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeScreenAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(90);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final String monthLabel = DateFormat('MMMM', 'en_US').format(now);
    final String weekdayLabel = DateFormat('EEEE', 'en_US').format(now);

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.only(left: 18, right: 18, top: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  '$monthLabel ${now.day},',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  weekdayLabel,
                  style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: GradientCard(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                gradientVariant: AppGradients.card,
                child: Row(
                  children: [
                    Image.asset('assets/fire.png', height: 16, width: 16),
                    const SizedBox(width: 8),
                    _StreakWeekAsync(),
                  ],
                ),
              ),
            ),
          ],
        ),
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
