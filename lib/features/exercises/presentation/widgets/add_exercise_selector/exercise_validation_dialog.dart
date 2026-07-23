import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<bool> showExerciseValidationDialog(
  BuildContext context, {
  required String? name,
  required String? muscleGroup,
}) async {
  if (name != null && name.trim().isNotEmpty && muscleGroup != null) {
    return true;
  }

  await showDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: const Text('Name or muscle group empty'),
        content: const Text("Name and muscle group can't be empty."),
        actions: [
          CupertinoDialogAction(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );

  return false;
}
