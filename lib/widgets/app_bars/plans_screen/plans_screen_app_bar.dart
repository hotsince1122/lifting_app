import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/widgets/app_bars/app_bar_settings.dart';
import 'package:lifting_tracker_app/widgets/app_bars/plans_screen/target_week_button.dart';
import 'package:lifting_tracker_app/widgets/app_bars/screen_app_bar.dart';

class PlansAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PlansAppBar({super.key});

  @override
  Size get preferredSize => appBarHeight;

  @override
  Widget build(BuildContext context) {
    return ScreenAppBar(title: 'Plans', trailing: TargetWeekButton());
  }
}
