import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/models/entity/custom_split.dart';
import 'package:lifting_tracker_app/models/entity/split_day.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';

class CustomSplitSelector extends StatefulWidget {
  const CustomSplitSelector({super.key, required this.screenWidth});

  final double screenWidth;

  @override
  State<CustomSplitSelector> createState() => _CustomSplitSelectorState();
}

class _CustomSplitSelectorState extends State<CustomSplitSelector> {
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
    final days = _daysSplitSliderValue.toInt();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          width: widget.screenWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppColors.card.withAlpha(253),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: Navigator.of(context).pop,
                      iconSize: 18,
                      icon: const Icon(Icons.close),
                    ),
                    Text(
                      'Create Custom Split',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        if (_splitName.text.trim().isEmpty) {
                          setState(() {
                            _userTriedToSave = true;
                          });
                          return;
                        }

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
                        Navigator.of(context).pop((CustomSplit(_splitName.text.trim(), customSplit)));
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

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 6,),
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
                              (_userTriedToSave &&
                                  _splitName.text.trim().isEmpty)
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

                      const SizedBox(height: 6),
                      Text(
                        'How many training days per cycle?',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This will repeat after the last day.',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: AppColors.primary,
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
                      const SizedBox(height: 16),
                      Text(
                        "Name each workout day, in their order:",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You can edit names later.',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 340,
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
                                        color: AppColors.primary,
                                      ),
                                      child: Text(
                                        (i + 1).toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              color: AppColors.card,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
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
                                                  _dayNames[i].text
                                                      .trim()
                                                      .isEmpty)
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
                                const SizedBox(height: 4),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
