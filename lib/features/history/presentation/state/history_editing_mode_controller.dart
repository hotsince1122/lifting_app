import 'package:flutter_riverpod/flutter_riverpod.dart';

final historyEditModeProvider =
    NotifierProvider<HistoryEditModeController, bool>(
      HistoryEditModeController.new,
    );

class HistoryEditModeController extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }

  void exit() {
    state = false;
  }
}
