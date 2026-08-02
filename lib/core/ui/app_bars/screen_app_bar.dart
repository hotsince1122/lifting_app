import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/app_bars/app_bar_settings.dart';

class ScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ScreenAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Size get preferredSize => appBarHeight;

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
            height: appBarHeight.height,
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Visibility(
                        visible: subtitle != null,
                        maintainSize: true,
                        maintainState: true,
                        maintainAnimation: true,
                        child: Text(
                          subtitle ?? 'Placeholder',
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineLarge!
                            .copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
