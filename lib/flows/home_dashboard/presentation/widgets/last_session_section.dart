import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/card_flow/last_session_card_flow.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/widgets/home_summary_card.dart';

class LastSessionSection extends StatelessWidget {
  const LastSessionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeSummaryCard(flow: LastSessionCardFlow());
  }
}
