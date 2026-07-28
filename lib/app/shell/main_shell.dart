import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifting_tracker_app/core/ui/transitions/tab_body_transition.dart';
import 'package:lifting_tracker_app/features/history/presentation/state/history_editing_mode_controller.dart';
import 'package:lifting_tracker_app/features/plans/presentation/state/change_weekly_target_mode_controller.dart';
import 'package:lifting_tracker_app/features/history/presentation/pages/history_page.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/pages/home.dart';
import 'package:lifting_tracker_app/features/plans/presentation/pages/plans.dart';
import 'package:lifting_tracker_app/features/history/presentation/widgets/history_app_bar.dart';
import 'package:lifting_tracker_app/features/plans/presentation/widgets/plans_screen_app_bar.dart';
import 'package:lifting_tracker_app/app/shell/main_bottom_navigation.dart';
import 'package:lifting_tracker_app/flows/home_dashboard/presentation/widgets/home_screen_app_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  static const int _nrOfTabes = 3;

  static const List<PreferredSizeWidget?> _appBars = [
    HomeScreenAppBar(),
    HistoryAppBar(),
    PlansAppBar(),
  ];

  void _onTabSelected(int index, WidgetRef ref) {
    if (index < 0 || index > _nrOfTabes - 1) return;

    if (_currentIndex == 1 && index != 1) {
      ref.read(historyEditModeProvider.notifier).exit();
    }

    if (_currentIndex == 2 && index != 2) {
      ref.read(changeWeeklyTargetMode.notifier).exit();
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBars[_currentIndex],
      bottomNavigationBar: MainBottomNavigation(onTabSelected: _onTabSelected),
      body: TabBodyTransition(
        animationKey: _currentIndex,
        child: IndexedStack(
          index: _currentIndex,
          children: const [Home(), HistoryPage(), PlansPage()],
        ),
      ),
    );
  }
}
