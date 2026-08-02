import 'package:flutter/material.dart';

class WorkoutSetFocusNodes {
  WorkoutSetFocusNodes(int setId)
    : weight = FocusNode(debugLabel: 'weight-$setId'),
      reps = FocusNode(debugLabel: 'reps-$setId'),
      notes = FocusNode(debugLabel: 'notes-$setId');

  final FocusNode weight;
  final FocusNode reps;
  final FocusNode notes;

  void unfocus() {
    weight.unfocus();
    reps.unfocus();
    notes.unfocus();
  }

  void dispose() {
    weight.dispose();
    reps.dispose();
    notes.dispose();
  }
}
