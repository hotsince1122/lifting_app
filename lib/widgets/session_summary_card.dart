import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/providers/presentation/workout_header_summary_card.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/theme/app_gradients.dart';
import 'package:lifting_tracker_app/widgets/gradient_cards.dart';

class SessionSummaryCard extends ConsumerWidget {
  const SessionSummaryCard({required this.sessionId, super.key});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionSummaryCardAsync = ref.watch(
      workoutHeaderSummaryCardProvider(sessionId),
    );

    String transformIntoDateLabel(DateTime? date) {
      if (date == null) return '-';

      final weekday = DateFormat('EEE', 'en_US').format(date);
      final month = DateFormat('MMM', 'en_US').format(date);
      final day = date.day;

      final hour = date.hour;
      final minute = date.minute;
      final time = '${hour < 10 ? '0$hour' : hour}:${minute < 10 ? '0$minute' : minute}';

      return '$weekday, $day $month at $time';
    }

    Widget infoTile(String title, String description) {
      return Row(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: AppColors.primary,
              letterSpacing: 0.1,
            ),
          ),
        ],
      );
    }

    return sessionSummaryCardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) =>
          const Center(child: Text('An error has occured! Try again.')),
      data: (sessionSummaryCard) {
        final startTimeLabel = transformIntoDateLabel(
          sessionSummaryCard!.startTime,
        );
        final endTimeLabel = transformIntoDateLabel(sessionSummaryCard.endTime);
        String durationInMinutes = (sessionSummaryCard.workoutDurationInMinutes)
            .toString();
        if (durationInMinutes == 'null') durationInMinutes = '-';

        return AspectRatio(
          aspectRatio: 1.55,
          child: GradientCard(
            gradientVariant: AppGradients.card,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:
                  [
                        Text(
                          sessionSummaryCard.workoutName,
                          style: Theme.of(context).textTheme.headlineSmall!
                              .copyWith(fontWeight: FontWeight.w900),
                        ),
                        infoTile('Start Time', startTimeLabel),
                        infoTile('End Time', endTimeLabel),
                        infoTile('Duration', durationInMinutes),
                      ]
                      .expand(
                        (item) => [
                          item,
                          const Divider(height: 1, color: AppColors.cardBorder),
                        ],
                      )
                      .toList()
                    ..removeLast(),
            ),
          ),
        );
      },
    );
  }
}