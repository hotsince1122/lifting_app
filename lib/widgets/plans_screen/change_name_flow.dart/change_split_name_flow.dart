import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:lifting_tracker_app/providers/persisted/split_name.dart';
import 'package:lifting_tracker_app/widgets/plans_screen/change_name_flow.dart/change_name_contract.dart';

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
