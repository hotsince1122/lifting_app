import 'package:flutter/material.dart';

class SheetHeaderConfig {
  const SheetHeaderConfig({
    required this.title,
    required this.leading,
    required this.trailing,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
}

class SheetHeader extends StatelessWidget {
  const SheetHeader({required this.config, super.key});

  final SheetHeaderConfig config;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(config.title, style: Theme.of(context).textTheme.titleMedium),
        Align(alignment: Alignment.centerLeft, child: config.leading),
        Align(alignment: Alignment.centerRight, child: config.trailing),
      ],
    );
  }
}