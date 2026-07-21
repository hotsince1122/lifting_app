import 'package:flutter/material.dart';

abstract class DeleteFlow {
  const DeleteFlow();

  String get title;
  String get content;

  Future<bool> canShowConfirmation (BuildContext context) async {
    return true;
  }

  Future<void> onDelete(BuildContext context);
}
