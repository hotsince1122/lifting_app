import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/solid_button.dart';
import 'package:lifting_tracker_app/widgets/solid_card.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ActiveSessionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ActiveSessionAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(90);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final dayLabel = now.day.toString();
    final monthLabel = DateFormat('MMM', 'en_US').format(now);
    final double buttonHeight = 46;
    final double iconSize = 26;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SolidButton(
            onPressed: () => Navigator.of(context).pop(),
            color: AppColors.card,
            buttonHeight: buttonHeight,
            buttonWidth: 58,
            padding: EdgeInsets.zero,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: iconSize,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),

          SolidButton(
            onPressed: () => Navigator.of(context).pop(),
            buttonHeight: buttonHeight,
            buttonWidth: 92,
            padding: EdgeInsets.zero,
            child: Text(
              'Finish',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          Text(
            '$dayLabel $monthLabel',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          SolidCard(
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: buttonHeight,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.timer_sharp,
                      size: iconSize,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () {},
                    icon: PhosphorIcon(
                      PhosphorIcons.dotsThreeOutline(PhosphorIconsStyle.bold),
                      size: iconSize,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
