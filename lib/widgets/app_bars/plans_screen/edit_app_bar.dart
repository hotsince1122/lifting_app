import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/ui/app_bars/app_bar_settings.dart';

class EditAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EditAppBar(this.title, {super.key});

  final String title;

  @override
  Size get preferredSize => appBarHeightSplitEditPages;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
      centerTitle: true,
      leading: IconButton(
        onPressed: Navigator.of(context).pop,
        icon: Icon(Icons.arrow_back_ios_rounded, size: 18),
      ),
    );
  }
}
