import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MainBottomNavigation extends ConsumerWidget {
  const MainBottomNavigation({
    required this.onTabSelected,
    required this.currentIndex,
    super.key,
  });

  final void Function(int, WidgetRef) onTabSelected;
  final int currentIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const int homeIndex = 0;
    const int historyIndex = 1;
    const int plansIndex = 2;
    const int progressIndex = 3;

    Widget navBarButton(String text, IconData icon, int tabIndex) {
      return AnimatedScale(
        scale: currentIndex == tabIndex ? 1 : 0.90,
        duration: Duration(milliseconds: 220),
        curve: Curves.bounceIn,
        child: AspectRatio(
          aspectRatio: 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              onTabSelected(tabIndex, ref);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PhosphorIcon(
                  icon,
                  size: 24,
                  color: currentIndex == tabIndex
                      ? AppColors.secondary
                      : AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  text,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    fontSize: 10,
                    color: currentIndex == tabIndex
                        ? AppColors.secondary
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              navBarButton('Home', PhosphorIcons.house(), homeIndex),
              navBarButton(
                'History',
                PhosphorIcons.clockCounterClockwise(),
                historyIndex,
              ),
              navBarButton('Plans', PhosphorIcons.squaresFour(), plansIndex),
              navBarButton(
                'Progress',
                PhosphorIcons.chartLineUp(),
                progressIndex,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
