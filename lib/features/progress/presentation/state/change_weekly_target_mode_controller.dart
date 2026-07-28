import 'package:flutter_riverpod/flutter_riverpod.dart';

final changeWeeklyTargetModeProvider =
    NotifierProvider<ChangeWeeklyTargetModeController, bool>(
      ChangeWeeklyTargetModeController.new,
    );

class ChangeWeeklyTargetModeController extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() {
    state = !state;
  }

  void exit() {
    state = true;
  }
}
