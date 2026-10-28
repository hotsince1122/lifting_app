import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/theme/app_gradients.dart';

abstract class HomeSummaryCardFlow {
  const HomeSummaryCardFlow();

  Widget buildHeader(BuildContext context, WidgetRef ref);

  Widget buildContent(BuildContext context, WidgetRef ref);

  final gradient = AppGradients.card;
}
