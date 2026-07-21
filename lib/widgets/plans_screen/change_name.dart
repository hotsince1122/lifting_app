import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/plans_screen/change_name_flow.dart/change_name_contract.dart';

class ChangeName extends ConsumerStatefulWidget {
  const ChangeName({required this.flow, required super.key});

  final ChangeNameFlow flow;

  @override
  ConsumerState<ChangeName> createState() => _ChangeNameState();
}

class _ChangeNameState extends ConsumerState<ChangeName> {
  TextEditingController? _nameController;
  Timer? _renameDebounce;
  String? _pendingName;

  @override
  void dispose() {
    _renameDebounce?.cancel();

    final pendingName = _pendingName;

    if (pendingName != null) {
      unawaited(widget.flow.changeName(ref, pendingName));
    }

    _nameController?.dispose();
    super.dispose();
  }

  void _syncNameWithController(String name) {
    final controller = _nameController;

    if (controller == null) {
      _nameController = TextEditingController(text: name);
      return;
    }

    if (controller.text == name) return;

    controller.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );
  }

  void _handleNameChanged(String newName) {
    _pendingName = newName;
    _renameDebounce?.cancel();

    _renameDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_savePendingName());
    });
  }

  Future<void> _savePendingName() async {
    final name = _pendingName;

    if (name == null) return;

    _renameDebounce?.cancel();
    _renameDebounce = null;
    _pendingName = null;

    await widget.flow.changeName(ref, name);
  }

  @override
  Widget build(BuildContext context) {
    final nameAsync = ref.watch(widget.flow.nameProvider);

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.flow.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.onSurfaceMuted),
          ),
          const SizedBox(height: 8),
          nameAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                const Center(child: Text('An error has occurred.')),
            data: (name) {
              _syncNameWithController(name);

              return TextField(
                controller: _nameController,
                onChanged: _handleNameChanged,
                onSubmitted: (_) {
                  unawaited(_savePendingName());
                },
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                maxLines: 2,
                minLines: 1,

                style: Theme.of(context).textTheme.bodyLarge,

                decoration: InputDecoration(
                  hintText: widget.flow.title,

                  filled: true,
                  fillColor: AppColors.secondary.withAlpha(18),

                  hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: AppColors.cardBorder,
                      width: 1.2,
                    ),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: AppColors.primaryTransparent,
                      width: 1.2,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
