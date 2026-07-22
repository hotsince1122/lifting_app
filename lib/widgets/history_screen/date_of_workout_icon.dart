import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_gradients.dart';

class DateOfWorkoutIcon extends StatelessWidget {
  const DateOfWorkoutIcon({
    required this.weekday,
    required this.calendarDay,
    super.key,
  });

  final String weekday;
  final int calendarDay;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: SizedBox.square(
        dimension: 48,
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppThemeGradients.of(
                    AppGradients.primaryColorTransparent,
                  ),
                  border: BoxBorder.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  weekday,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.card,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppThemeGradients.of(AppGradients.spotlightCard),
                  border: BoxBorder.all(color: AppColors.cardBorder),
                ),
                child: Text(
                  '$calendarDay',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
