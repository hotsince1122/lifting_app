import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/data/animations/tab_body_transition.dart';
import 'package:lifting_tracker_app/screens/history.dart';
import 'package:lifting_tracker_app/screens/home.dart';
import 'package:lifting_tracker_app/widgets/appBars/history_screen_app_bar.dart';
import 'package:lifting_tracker_app/widgets/homescreen/bottom_nav_bar.dart';
import 'package:lifting_tracker_app/widgets/appBars/home_screen_app_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  static const int _nrOfTabes = 2;

  static const List<PreferredSizeWidget?> _appBars = [
    HomeScreenAppBar(),
    HistoryAppBar(),
  ];

  void _onTabSelected(int index) {
    if (index < 0 || index > _nrOfTabes - 1) return;

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBars[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(onTabSelected: _onTabSelected),
      body: TabBodyTransition(
        animationKey: _currentIndex,
        child: IndexedStack(
          index: _currentIndex,
          children: const [Home(), History()],
        ),
      ),
    );
  }
}
