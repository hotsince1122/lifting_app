import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:lifting_tracker_app/providers/persisted/day_name.dart';
import 'package:lifting_tracker_app/widgets/plans_screen/change_name_flow.dart/change_name_contract.dart';

class ChangeDayNameFlow extends ChangeNameFlow {
  const ChangeDayNameFlow({required this.dayId});

  final String dayId;

  @override
  String get title => 'Day name';

  @override
  Future<void> changeName(WidgetRef ref, String newName) async {
    await ref.read(dayNameProvider(dayId).notifier).renameDay(newName);
  }

  @override
  ProviderListenable<AsyncValue<String>> get nameProvider {
    return dayNameProvider(dayId);
  }
}
