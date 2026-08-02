import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:lifting_tracker_app/core/theme/app_gradients.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/core/ui/cards/gradient_card.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/card_flow/home_summary_card_flow.dart';

const double _headerExtent = 32;
const double _loadingIndicatorSize = 24;

class HomeSummaryCard extends ConsumerWidget {
  const HomeSummaryCard({required this.flow, super.key});

  final HomeSummaryCardFlow flow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GradientCard(
      gradientVariant: AppGradients.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _headerExtent,
            child: flow.buildHeader(context, ref),
          ),
          const SizedBox(height: AppSpacing.s8),
          flow.buildContent(context, ref),
        ],
      ),
    );
  }
}

class HomeSummaryCardHeader extends StatelessWidget {
  const HomeSummaryCardHeader({
    required this.leading,
    required this.title,
    super.key,
  });

  final Widget leading;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox.square(
          dimension: _headerExtent,
          child: Center(child: leading),
        ),
        const SizedBox(width: AppSpacing.s4),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    );
  }
}

class HomeSummaryCardContent extends StatelessWidget {
  const HomeSummaryCardContent.details({
    required this.primaryText,
    required this.secondaryText,
    this.detailText,
    this.detailLeading,
    super.key,
  }) : _isMessage = false;

  const HomeSummaryCardContent.message({
    required this.primaryText,
    required this.secondaryText,
    super.key,
  }) : detailText = null,
       detailLeading = null,
       _isMessage = true;

  final String primaryText;
  final String secondaryText;
  final String? detailText;
  final Widget? detailLeading;
  final bool _isMessage;

  @override
  Widget build(BuildContext context) {
    final secondaryStyle = _isMessage
        ? Theme.of(
            context,
          ).textTheme.labelMedium!.copyWith(color: AppColors.onSurfaceMuted)
        : Theme.of(
            context,
          ).textTheme.bodySmall!.copyWith(color: AppColors.secondary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          primaryText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w900),
        ),
        SizedBox(height: _isMessage ? AppSpacing.s8 : AppSpacing.s4),
        Text(
          secondaryText,
          maxLines: _isMessage ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: secondaryStyle,
        ),
        if (detailText case final detailText?) ...[
          const SizedBox(height: AppSpacing.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (detailLeading case final detailLeading?) ...[
                detailLeading,
                const SizedBox(width: AppSpacing.s4),
              ],
              Expanded(
                child: Text(
                  detailText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium!.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class HomeSummaryCardLoading extends StatelessWidget {
  const HomeSummaryCardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: _loadingIndicatorSize,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class HomeSummaryCardError extends StatelessWidget {
  const HomeSummaryCardError({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'An error has occurred.',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.labelMedium!.copyWith(color: AppColors.primary),
      ),
    );
  }
}
