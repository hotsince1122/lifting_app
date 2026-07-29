import 'package:flutter/material.dart';

class SnackBarError extends SnackBar {
  SnackBarError(String message, {super.key}) : super(content: Text(message));

  static void show(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBarError(message));
  }
}
