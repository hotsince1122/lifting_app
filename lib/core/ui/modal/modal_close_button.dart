import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ModalCloseButton extends StatelessWidget {
  const ModalCloseButton({this.onPressed, this.isEnabled = true, super.key});

  final VoidCallback? onPressed;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Close',
      onPressed: isEnabled
          ? onPressed ?? () => Navigator.of(context).maybePop()
          : null,
      icon: PhosphorIcon(
        PhosphorIcons.x(),
        size: 18,
        color: isEnabled ? AppColors.primary : AppColors.onSurfaceMuted,
      ),
    );
  }
}
