import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/providers/presentation/history_editing_mode.dart';
import 'package:lifting_tracker_app/providers/presentation/history_months.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/appBars/app_bar_settings.dart';
import 'package:lifting_tracker_app/widgets/appBars/screen_app_bar.dart';

class HistoryAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const HistoryAppBar({super.key});

  @override
  Size get preferredSize => appBarHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyMonthsAsync = ref.watch(historyMonthsProvider);

    final Widget editButton = historyMonthsAsync.when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text('An error has occured! Try again.')),
      data: (historyMonthsData) {
        bool isNotTappable = historyMonthsData.isEmpty;

        if (isNotTappable) ref.invalidate(historyEditModeProvider);

        return AnimatedScale(
          scale: isNotTappable ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: AnimatedOpacity(
            opacity: isNotTappable ? 0.45 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: TextButton(
              onPressed: isNotTappable
                  ? () {}
                  : () => ref.read(historyEditModeProvider.notifier).toggle(),
              style: TextButton.styleFrom(
                side: BorderSide(color: AppColors.cardBorder),
                backgroundColor: AppColors.onCardTransparent,
              ),
              child: Text(
                'Edit',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(color: AppColors.onSurface),
              ),
            ),
          ),
        );
      },
    );

    return ScreenAppBar(title: 'History', trailing: editButton);
  }
}
