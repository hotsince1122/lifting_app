import 'package:flutter_riverpod/flutter_riverpod.dart';

final changeWeeklyTargetMode =
    NotifierProvider<ChangeWeeklyTargetModeNotifier, bool>(
      ChangeWeeklyTargetModeNotifier.new,
    );

class ChangeWeeklyTargetModeNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() {
    state = !state;
  }

  void exit() {
    state = true;
  }
}
