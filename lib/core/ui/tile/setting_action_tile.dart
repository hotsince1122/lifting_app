import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum SettingActionTone { standard, destructive }

class SettingActionTile extends StatelessWidget {
  const SettingActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.leading,
    this.tone = SettingActionTone.standard,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final SettingActionTone tone;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    final isDestructive = tone == SettingActionTone.destructive;
    final accentColor = isDestructive ? Colors.red : AppColors.primary;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.20),
                  ),
                ),
                child: PhosphorIcon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: isDestructive ? Colors.red : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
              leading,
            ],
          ),
        ),
      ),
    );
  }
}

class SettingActionDivider extends StatelessWidget {
  const SettingActionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      color: AppColors.cardBorder,
      endIndent: 12,
      indent: 12,
    );
  }
}
