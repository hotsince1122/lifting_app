import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({required this.onTabSelected, super.key});

  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {

    const int homeIndex = 0;
    const int historyIndex = 1;
    const int plansIndex = 2;
    const int settingsIndex = 3;

    Widget navBarButton(String text, IconData icon, int tabIndex) {
      return AspectRatio(
        aspectRatio: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            // print(tabIndex);
            onTabSelected(tabIndex);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(icon, color: AppColors.primary),
              const SizedBox(height: 4),
              Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium!.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 20, 26, 34),
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              navBarButton('Home', PhosphorIcons.house(), homeIndex),
              navBarButton('History', PhosphorIcons.clockCounterClockwise(), historyIndex),
              navBarButton('Plans', PhosphorIcons.squaresFour(), plansIndex),
              navBarButton('Settings', PhosphorIcons.gear(), settingsIndex),
            ],
          ),
        ),
      ),
    );
  }
}
