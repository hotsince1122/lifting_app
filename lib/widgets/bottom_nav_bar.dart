import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 20, 26, 34),
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(PhosphorIcons.house(), color: AppColors.primary),
                  const SizedBox(height: 4,),
                  Text(
                    'Home',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium!.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(PhosphorIcons.clockCounterClockwise(), color: AppColors.primary),
                  const SizedBox(height: 4,),
                  Text(
                    'History',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium!.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(PhosphorIcons.squaresFour(), color: AppColors.primary),
                  const SizedBox(height: 4,),
                  Text(
                    'Plans',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium!.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(PhosphorIcons.gear(), color: AppColors.primary),
                  const SizedBox(height: 4,),
                  Text(
                    'Settings',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium!.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
