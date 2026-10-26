import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/ui/app_bars/app_bar_settings.dart';
import 'package:lifting_tracker_app/core/ui/app_bars/screen_app_bar.dart';

class ProgressAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProgressAppBar({super.key});

  @override
  Size get preferredSize => appBarHeight;

  @override
  Widget build(BuildContext context) {
    return ScreenAppBar(title: 'Progress');
  } 
}