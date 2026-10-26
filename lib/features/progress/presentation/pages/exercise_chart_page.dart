import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/core/extensions/double_extensions.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/features/exercises/domain/catalog_exercise.dart';
import 'package:lifting_tracker_app/features/progress/application/exercise_progress_sets_provider.dart';
import 'package:lifting_tracker_app/features/progress/domain/exercise_progress_calculations.dart';
import 'package:lifting_tracker_app/features/progress/domain/exercise_progress_set.dart';
import 'package:lifting_tracker_app/features/progress/presentation/widgets/cupertino_sliding_segmented_control_custom.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

enum ChartMetric { maxWeight, bestSet, allSets }

class ExerciseChartPage extends ConsumerStatefulWidget {
  const ExerciseChartPage(this.exercise, {super.key});

  final CatalogExercise exercise;

  static Future<void> openPage(
    BuildContext context,
    CatalogExercise exercise,
  ) async {
    final navigator = Navigator.of(context);

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    try {
      await navigator.push(
        MaterialPageRoute(builder: (_) => ExerciseChartPage(exercise)),
      );
    } finally {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  @override
  ConsumerState<ExerciseChartPage> createState() => _ExerciseChartPageState();
}

class _ExerciseChartPageState extends ConsumerState<ExerciseChartPage> {
  ChartMetric _selectedMetric = ChartMetric.bestSet;

  int? _selectedSetId;

  void _selectSet(int setId) {
    if (_selectedSetId == setId) return;

    setState(() {
      _selectedSetId = setId;
    });
  }

  Widget _segment(String title, ChartMetric metric) {
    final isSelected = _selectedMetric == metric;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;

    final exerciseProgressAsync = ref.watch(
      exerciseProgressSetsProvider(exercise.id),
    );

    final List<ExerciseProgressSet> exerciseProgressSets = exerciseProgressAsync
        .when(
          loading: () => [],
          error: (_, _) => [],
          data: (sets) {
            switch (_selectedMetric) {
              case ChartMetric.allSets:
                return sets;
              case ChartMetric.bestSet:
                return bestSetBySession(sets);
              case ChartMetric.maxWeight:
                return maxWeightSetBySession(sets);
            }
          },
        );

    final hasHistory = exerciseProgressSets.isNotEmpty;
    final matchingIndex = exerciseProgressSets.indexWhere(
      (set) => set.setId == _selectedSetId,
    );
    final selectedIndex = matchingIndex >= 0
        ? matchingIndex
        : exerciseProgressSets.length - 1;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppSpacing.s48,
        leading: _BackButton(),
        title: Text(
          exercise.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.s8),
            child: _FavoriteButton(exercise),
          ),
        ],
      ),
      body: exerciseProgressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Could not load progress.')),
        data: (_) => SafeArea(
          left: true,
          right: true,
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.s16,
              right: AppSpacing.s16,
              bottom: AppSpacing.s32,
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (hasHistory)
                        _ChartPointDetails(
                          set: exerciseProgressSets[selectedIndex],
                          metric: _selectedMetric,
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No history yet',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: AppSpacing.s4),
                            Text(
                              'Completed sessions will appear here.',
                              style: Theme.of(context).textTheme.bodySmall!
                                  .copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      CupertinoSlidingSegmentedControlCustom<ChartMetric>(
                        children: {
                          ChartMetric.maxWeight: _segment(
                            'Max weight',
                            ChartMetric.maxWeight,
                          ),
                          ChartMetric.bestSet: _segment(
                            'Best set',
                            ChartMetric.bestSet,
                          ),
                          ChartMetric.allSets: _segment(
                            'All sets',
                            ChartMetric.allSets,
                          ),
                        },
                        onValueChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedMetric = value;
                              _selectedSetId = null;
                            });
                          }
                        },
                        groupValue: _selectedMetric,
                        backgroundColor: AppColors.card,
                        thumbColor: AppColors.primary,
                        trackRadius: const Radius.circular(20),
                        thumbRadius: const Radius.circular(18),
                        selectedLabelColor: AppColors.card,
                        unselectedLabelColor: AppColors.primary,
                        padding: EdgeInsets.all(AppSpacing.s4),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Expanded(
                    child: hasHistory
                        ? _Chart(
                            sets: exerciseProgressSets,
                            selectedIndex: selectedIndex,
                            selectedMetric: _selectedMetric,
                            onSetSelected: _selectSet,
                          )
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.trending_up_rounded,
                                  size: 32,
                                  color: AppColors.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.s16),
                                Text(
                                  'No completed sets for this exercise',
                                  style: Theme.of(context).textTheme.bodySmall!
                                      .copyWith(color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartPointDetails extends StatelessWidget {
  const _ChartPointDetails({required this.set, required this.metric});

  final ExerciseProgressSet set;
  final ChartMetric metric;

  @override
  Widget build(BuildContext context) {
    final title = switch (metric) {
      ChartMetric.maxWeight => set.weight.formatted,
      ChartMetric.bestSet || ChartMetric.allSets => set.weightReps.formatted,
    }.replaceAll('.', ',');

    final metricLabel = switch (metric) {
      ChartMetric.maxWeight => "kg",
      ChartMetric.bestSet || ChartMetric.allSets => "kg × reps",
    };

    final subtitle = switch (metric) {
      ChartMetric.maxWeight || ChartMetric.bestSet =>
        "${set.weight.formatted} kg × ${set.repetitions} reps · ${DateFormat('dd MMM').format(set.sessionStartedAt)}",
      ChartMetric.allSets =>
        "${set.weight.formatted} kg × ${set.repetitions} reps · ${DateFormat('dd MMM').format(set.sessionStartedAt)} · Set ${set.setIndex}",
    }.replaceAll('.', ',');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(title, style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(width: AppSpacing.s4),
            Text(
              metricLabel,
              style: Theme.of(
                context,
              ).textTheme.titleSmall!.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.s4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.labelLarge!.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}

class _Chart extends StatefulWidget {
  const _Chart({
    required this.sets,
    required this.selectedIndex,
    required this.selectedMetric,
    required this.onSetSelected,
  });

  final List<ExerciseProgressSet> sets;
  final int selectedIndex;
  final ChartMetric selectedMetric;
  final ValueChanged<int> onSetSelected;

  @override
  State<StatefulWidget> createState() => _ChartState();
}

class _ChartState extends State<_Chart> {
  late final ZoomPanBehavior _zoomPanBehavior;

  @override
  void initState() {
    super.initState();

    _zoomPanBehavior = ZoomPanBehavior(
      enablePanning: true,
      enablePinching: true,
      zoomMode: ZoomMode.x,
    );
  }

  double _getYValue(ExerciseProgressSet set) {
    return switch (widget.selectedMetric) {
      ChartMetric.maxWeight => set.weight,
      ChartMetric.bestSet || ChartMetric.allSets => set.weightReps,
    };
  }

  void _onPointTap(ChartPointDetails details) {
    final index = details.pointIndex;
    if (index == null || index < 0 || index >= widget.sets.length) {
      return;
    }

    widget.onSetSelected(widget.sets[index].setId);
  }

  @override
  Widget build(BuildContext context) {
    final sets = widget.sets;
    final selectedIndex = widget.selectedIndex;
    final selectedSet = sets[selectedIndex];
    final isAllSets = widget.selectedMetric == ChartMetric.allSets;
    final visiblePointCount = isAllSets ? 24 : 8;
    final zoomFactor = sets.length > visiblePointCount
        ? visiblePointCount / sets.length
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.selectedMetric == ChartMetric.maxWeight ? 'kg' : 'kg × reps',
          style: Theme.of(
            context,
          ).textTheme.labelMedium!.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.s12),
        Expanded(
          child: SfCartesianChart(
            key: ValueKey(widget.selectedMetric),
            margin: EdgeInsets.zero,
            plotAreaBorderWidth: 0,
            zoomPanBehavior: _zoomPanBehavior,

            primaryXAxis: NumericAxis(
              minimum: 0,
              maximum: sets.length > 1 ? (sets.length - 1).toDouble() : 1.0,
              interval: 1,
              enableAutoIntervalOnZooming: false,
              edgeLabelPlacement: EdgeLabelPlacement.shift,
              initialZoomFactor: zoomFactor,
              initialZoomPosition: 1.0 - zoomFactor,

              plotOffsetStart: 12,
              plotOffsetEnd: 12,

              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(width: 0),
              majorGridLines: const MajorGridLines(width: 0),

              labelStyle: Theme.of(
                context,
              ).textTheme.labelMedium!.copyWith(color: AppColors.primary),

              axisLabelFormatter: (details) {
                final index = details.value.round();

                if (index < 0 || index >= sets.length) {
                  return ChartAxisLabel('', details.textStyle);
                }

                if (index > 0 &&
                    DateUtils.isSameDay(
                      sets[index].sessionStartedAt,
                      sets[index - 1].sessionStartedAt,
                    )) {
                  return ChartAxisLabel('', details.textStyle);
                }

                return ChartAxisLabel(
                  DateFormat('d MMM').format(sets[index].sessionStartedAt),
                  details.textStyle,
                );
              },

              plotBands: [
                if (isAllSets)
                  for (var index = 1; index < sets.length; index++)
                    if (!DateUtils.isSameDay(
                      sets[index - 1].sessionStartedAt,
                      sets[index].sessionStartedAt,
                    ))
                      PlotBand(
                        start: index - 0.5,
                        end: index - 0.5,
                        borderColor: AppColors.primaryTransparent,
                        borderWidth: 1,
                        dashArray: const [3, 5],
                      ),
                PlotBand(
                  start: selectedIndex,
                  end: selectedIndex,
                  borderColor: AppColors.primaryTransparent,
                  borderWidth: 1,
                  dashArray: const [3, 5],
                ),
              ],
            ),

            primaryYAxis: NumericAxis(
              minimum: 0,
              desiredIntervals: 4,
              anchorRangeToVisiblePoints: false,

              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(width: 0),

              majorGridLines: const MajorGridLines(
                color: AppColors.primaryTransparent,
                width: 0.7,
                dashArray: [3, 5],
              ),

              labelStyle: Theme.of(
                context,
              ).textTheme.labelMedium!.copyWith(color: AppColors.primary),
            ),

            series: <CartesianSeries>[
              if (isAllSets)
                ScatterSeries<ExerciseProgressSet, int>(
                  dataSource: sets,
                  xValueMapper: (_, index) => index,
                  yValueMapper: (set, _) => _getYValue(set),
                  color: AppColors.primary,
                  borderWidth: 0,
                  animationDuration: 0,
                  markerSettings: const MarkerSettings(
                    isVisible: false,
                    shape: DataMarkerType.circle,
                    width: 5,
                    height: 5,
                  ),
                  onPointTap: _onPointTap,
                )
              else
                LineSeries<ExerciseProgressSet, int>(
                  dataSource: sets,
                  xValueMapper: (_, index) => index,
                  yValueMapper: (set, _) => _getYValue(set),
                  color: AppColors.primary,
                  width: 1.6,
                  animationDuration: 0,
                  markerSettings: const MarkerSettings(
                    isVisible: true,
                    shape: DataMarkerType.circle,
                    width: 6,
                    height: 6,
                    color: AppColors.primary,
                    borderWidth: 0,
                  ),
                  onPointTap: _onPointTap,
                ),
              ScatterSeries<ExerciseProgressSet, int>(
                dataSource: [selectedSet],
                xValueMapper: (_, _) => selectedIndex,
                yValueMapper: (set, _) => _getYValue(set),
                color: AppColors.background,
                borderColor: AppColors.primaryTransparent,
                borderWidth: 1,
                animationDuration: 0,
                enableTooltip: false,
                enableTrackball: false,
                markerSettings: const MarkerSettings(
                  isVisible: false,
                  shape: DataMarkerType.circle,
                  width: 22,
                  height: 22,
                ),
              ),
              ScatterSeries<ExerciseProgressSet, int>(
                dataSource: [selectedSet],
                xValueMapper: (_, _) => selectedIndex,
                yValueMapper: (set, _) => _getYValue(set),
                color: AppColors.secondary,
                borderWidth: 0,
                animationDuration: 0,
                enableTooltip: false,
                enableTrackball: false,
                markerSettings: const MarkerSettings(
                  isVisible: false,
                  shape: DataMarkerType.circle,
                  width: 10,
                  height: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.of(context).pop(),
      icon: Icon(Icons.arrow_back_ios_rounded, size: 22),
    );
  }
}

class _FavoriteButton extends ConsumerStatefulWidget {
  const _FavoriteButton(this.exercise);

  final CatalogExercise exercise;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      icon: Icon(Icons.star_rounded, color: AppColors.primary),
    );
  }
}
