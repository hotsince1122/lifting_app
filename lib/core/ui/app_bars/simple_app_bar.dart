import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/ui/app_bars/app_bar_settings.dart';

class SimpleAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SimpleAppBar(this.title, {this.isTitleCentered = false, super.key});

  final String title;
  final bool isTitleCentered;

  @override
  Size get preferredSize => compactAppBarHeight;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Stack(
      fit: StackFit.passthrough,

      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topInset,
          child: ColoredBox(color: AppColors.background),
        ),

        SafeArea(
          child: Container(
            height: compactAppBarHeight.height,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentGeometry.topCenter,
                end: AlignmentGeometry.bottomCenter,
                colors: [
                  AppColors.background,
                  AppColors.background,
                  AppColors.background.withValues(alpha: 0.85),
                  AppColors.background.withValues(alpha: 0.45),
                  AppColors.background.withValues(alpha: 0),
                ],
                stops: const [0.0, 0.55, 0.68, 0.84, 1.0],
              ),
            ),
            child: Padding(
              padding: appBarPadding,
              child: NavigationToolbar(
                centerMiddle: isTitleCentered,
                leading: IconButton(
                  onPressed: Navigator.of(context).pop,
                  style: IconButton.styleFrom(shape: const CircleBorder()),
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                ),
                middle: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
