import 'package:flutter_riverpod/flutter_riverpod.dart';

final changeWeeklyTargetMode =
    NotifierProvider<ChangeWeeklyTargetModeConteoller, bool>(
      ChangeWeeklyTargetModeConteoller.new,
    );

class ChangeWeeklyTargetModeConteoller extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() {
    state = !state;
  }

  void exit() {
    state = true;
  }
}
