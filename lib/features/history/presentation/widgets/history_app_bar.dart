import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/features/history/presentation/state/history_editing_mode_controller.dart';
import 'package:lifting_tracker_app/features/history/application/history_months_provider.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/ui/app_bars/app_bar_settings.dart';
import 'package:lifting_tracker_app/core/ui/app_bars/screen_app_bar.dart';

class HistoryAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const HistoryAppBar({super.key});

  @override
  Size get preferredSize => appBarHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyMonthsAsync = ref.watch(historyMonthsProvider);
    final isEditingMode = ref.watch(historyEditModeProvider);

    ref.listen(historyMonthsProvider, (_, next) {
      if (next.value?.isEmpty ?? false) {
        ref.read(historyEditModeProvider.notifier).exit();
      }
    });

    final Widget editButton = historyMonthsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          const Center(child: Text('An error has occured! Try again.')),
      data: (historyMonthsData) {
        final isNotTappable = historyMonthsData.isEmpty;

        return AnimatedScale(
          scale: isNotTappable ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: AnimatedOpacity(
            opacity: isNotTappable ? 0.45 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: TextButton(
              onPressed: isNotTappable
                  ? null
                  : ref.read(historyEditModeProvider.notifier).toggle,
              style: TextButton.styleFrom(
                side: BorderSide(
                  color: isEditingMode
                      ? AppColors.secondary.withAlpha(80)
                      : AppColors.cardBorder,
                ),
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
