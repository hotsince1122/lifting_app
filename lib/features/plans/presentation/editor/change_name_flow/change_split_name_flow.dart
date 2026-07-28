import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:lifting_tracker_app/features/plans/application/split_name_controller.dart';
import 'package:lifting_tracker_app/features/plans/presentation/editor/change_name_flow/change_name_contract.dart';

class ChangeSplitNameFlow extends ChangeNameFlow {
  const ChangeSplitNameFlow({required this.splitId});

  final int splitId;

  @override
  String get title => 'Split name';

  @override
  Future<void> changeName(WidgetRef ref, String newName) async {
    await ref.read(splitNameProvider(splitId).notifier).renameSplit(newName);
  }

  @override
  ProviderListenable<AsyncValue<String>> get nameProvider {
    return splitNameProvider(splitId);
  }
}
