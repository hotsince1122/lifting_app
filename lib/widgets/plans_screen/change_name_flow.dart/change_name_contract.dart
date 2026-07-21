import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

abstract class ChangeNameFlow {
  const ChangeNameFlow();

  String get title;

  ProviderListenable<AsyncValue<String>> get nameProvider;

  Future<void> changeName(WidgetRef ref, String newName);
}