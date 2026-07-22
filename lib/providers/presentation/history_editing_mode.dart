import 'package:flutter_riverpod/flutter_riverpod.dart';

final historyEditModeProvider = NotifierProvider<HistoryEditModeNotifier, bool>(
  HistoryEditModeNotifier.new,
);

class HistoryEditModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }

  void exit() {
    state = false;
  }
}
