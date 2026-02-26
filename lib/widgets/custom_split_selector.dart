import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/models/split_days.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';

class CustomSplitSelector extends StatefulWidget {
  const CustomSplitSelector({super.key, required this.screenWidth});

  final double screenWidth;

  @override
  State<CustomSplitSelector> createState() => _CustomSplitSelectorState();
}

class _CustomSplitSelectorState extends State<CustomSplitSelector> {
  double _daysSplitSliderValue = 2;

  final List<TextEditingController> _dayNames = [];
  bool _userTriedToSave = false;

  void _syncControllersWithDays(int days) {
    while (_dayNames.length < days) {
      _dayNames.add(TextEditingController());
    }
    while (_dayNames.length > days) {
      _dayNames.removeLast().dispose();
    }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysSplitSliderValue.toInt();

    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 16, vertical: 32),
      child: Container(
        height: 450,
        width: widget.screenWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppColors.darkCardsMain.withAlpha(253),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: Navigator.of(context).pop,
                    iconSize: 18,
                    icon: const Icon(Icons.close),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      final List<SplitDay> customSplit = [];
                      for (int i = 0; i < days; i++) {
                        if (_dayNames[i].text.trim().isEmpty) {
                          setState(() {
                            _userTriedToSave = true;
                          });
                          return;
                        }
                        customSplit.add(
                          SplitDay(
                            name: _dayNames[i].text.trim(),
                            orderIndex: i,
                          ),
                        );
                      }

                      Navigator.of(context).pop(customSplit);
                    },
                    child: Text(
                      'Save',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'How many training days per cycle?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'This will repeat after the last day.',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppColors.accentLightBlue,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: Slider(
                  value: _daysSplitSliderValue,
                  autofocus: true,
                  max: 7,
                  min: 1,
                  divisions: 6,
                  activeColor: AppColors.accentLightWhite,
                  inactiveColor: AppColors.darkCardsSecodary,
                  label: '${_daysSplitSliderValue.toInt().toString()}-day cycle',
                  thumbColor: AppColors.accentLightBlue,
                  onChanged: (value) {
                    setState(() {
                      _userTriedToSave = false;
                      _daysSplitSliderValue = value;
                      _syncControllersWithDays(value.toInt());
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Name each workout day, in their order:",
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'You can edit names later.',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppColors.accentLightBlue,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 182,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (
                        int i = 0;
                        i < _daysSplitSliderValue.toInt();
                        i++
                      ) ...[
                        Row(
                          children: [
                            Container(
                              height: 26,
                              width: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accentLightBlue,
                              ),
                              child: Text(
                                (i + 1).toString(),
                                style: Theme.of(context).textTheme.bodyMedium!
                                    .copyWith(
                                      color: AppColors.darkCardsMain,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: TextField(
                                controller: _dayNames[i],
                                onChanged: (_) {
                                  if(_userTriedToSave) {
                                    setState(() {});
                                  }
                                },
                                decoration: InputDecoration(
                                  helperText: '',
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.accentLightGray,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.accentLightGray,
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
                                      color: const Color.fromARGB(255, 194, 138, 131),
                                      width: 2,
                                    ),
                                  ),
                                  label: Text('Day ${i + 1}...'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}