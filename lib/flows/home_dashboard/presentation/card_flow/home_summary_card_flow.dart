import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class HomeSummaryCardFlow {
  const HomeSummaryCardFlow();

  Widget buildHeader(BuildContext context, WidgetRef ref);

  Widget buildContent(BuildContext context, WidgetRef ref);
}
