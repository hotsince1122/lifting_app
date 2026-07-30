import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/errors/snack_bar_error.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/features/plans/application/active_split_plan_controller.dart';
import 'package:lifting_tracker_app/features/plans/domain/custom_split.dart';
import 'package:lifting_tracker_app/features/plans/domain/split_day.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/ui/modal/modal_scaffold.dart';

class CustomSplitSelector extends ConsumerStatefulWidget {
  const CustomSplitSelector({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black12,
      isScrollControlled: true,
      builder: (ctx) => CustomSplitSelector(),
    );
  }

  @override
  ConsumerState<CustomSplitSelector> createState() =>
      _CustomSplitSelectorState();
}

class _CustomSplitSelectorState extends ConsumerState<CustomSplitSelector> {
  double _daysSplitSliderValue = 3;

  final List<TextEditingController> _dayNames = [];
  final TextEditingController _splitName = TextEditingController();
  bool _userTriedToSave = false;

  void _syncControllersWithDays(int days) {
    while (_dayNames.length < days) {
      _dayNames.add(TextEditingController());
    }
    while (_dayNames.length > days) {
      _dayNames.removeLast().dispose();
    }
  }

  Future<void> _save() async {
    final days = _daysSplitSliderValue.toInt();
    final splitName = _splitName.text.trim();
    final dayNames = [for (int i = 0; i < days; i++) _dayNames[i].text.trim()];

    setState(() {
      _userTriedToSave = true;
    });

    if (splitName.isEmpty || dayNames.any((name) => name.isEmpty)) {
      return;
    }

    final customSplit = [
      for (int i = 0; i < days; i++) SplitDay(name: dayNames[i], orderIndex: i),
    ];

    try {
      await ref
          .read(activeSplitPlanProvider.notifier)
          .addAndChangeToCustom(CustomSplit(splitName, customSplit));
    } catch (_) {
      if (!mounted) return;
      SnackBarError.show(
        context,
        'Custom split could not be created. Try again.',
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _syncControllersWithDays(_daysSplitSliderValue.toInt());
  }

  @override
  void dispose() {
    for (final controller in _dayNames) {
      controller.dispose();
    }
    _splitName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalScaffold(
      heightFactor: 0.8,
      Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(onClose: () => Navigator.of(context).pop(), onSave: _save),
            const SizedBox(height: AppSpacing.s4),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Name your split:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextField(
                      controller: _splitName,
                      onChanged: (_) {
                        if (_userTriedToSave) {
                          setState(() {});
                        }
                      },
                      decoration: InputDecoration(
                        helperText: '',
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.secondary,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.secondary,
                            width: 2,
                          ),
                        ),
                        errorText:
                            (_userTriedToSave && _splitName.text.trim().isEmpty)
                            ? 'Required'
                            : null,
                        errorBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color.fromARGB(255, 194, 138, 131),
                            width: 2,
                          ),
                        ),
                        label: Text('Split name...'),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s20),

                    Text(
                      'How many training days per cycle?',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'This will repeat after the last day.',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    SizedBox(
                      height: AppSpacing.s48,
                      child: Slider(
                        value: _daysSplitSliderValue,
                        autofocus: true,
                        max: 7,
                        min: 1,
                        divisions: 6,
                        activeColor: AppColors.onSurface,
                        inactiveColor: AppColors.surface,
                        label:
                            '${_daysSplitSliderValue.toInt().toString()}-day cycle',
                        thumbColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() {
                            _userTriedToSave = false;
                            _daysSplitSliderValue = value;
                            _syncControllersWithDays(value.toInt());
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s40),

                    Text(
                      "Name each workout day, in their order:",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'You can edit names later.',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Column(
                      children: [
                        for (
                          int i = 0;
                          i < _daysSplitSliderValue.toInt();
                          i++
                        ) ...[
                          Row(
                            children: [
                              Container(
                                height: AppSpacing.s24,
                                width: AppSpacing.s24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                                child: Text(
                                  (i + 1).toString(),
                                  style: Theme.of(context).textTheme.bodyMedium!
                                      .copyWith(
                                        color: AppColors.card,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s4),
                              Expanded(
                                child: TextField(
                                  controller: _dayNames[i],
                                  onChanged: (_) {
                                    if (_userTriedToSave) {
                                      setState(() {});
                                    }
                                  },
                                  decoration: InputDecoration(
                                    helperText: '',
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.secondary,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.secondary,
                                        width: 2,
                                      ),
                                    ),
                                    errorText:
                                        (_userTriedToSave &&
                                            _dayNames[i].text.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                                    errorBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: const Color.fromARGB(
                                          255,
                                          194,
                                          138,
                                          131,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                    label: Text('Day ${i + 1}...'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s4),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.s12),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose, required this.onSave});

  final VoidCallback onClose;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onClose,
          iconSize: 18,
          icon: const Icon(Icons.close),
        ),
        Text(
          'Create Custom Split',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        TextButton(
          onPressed: onSave,
          child: Text(
            'Save',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
