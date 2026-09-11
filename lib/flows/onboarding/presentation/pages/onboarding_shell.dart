import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/core/theme/app_spacing.dart';
import 'package:lifting_tracker_app/flows/onboarding/presentation/pages/pick_exercises_page.dart';
import 'package:lifting_tracker_app/flows/onboarding/presentation/pages/protect_your_progress_page.dart';
import 'package:lifting_tracker_app/flows/onboarding/presentation/pages/select_split_page.dart';
import 'package:lifting_tracker_app/flows/onboarding/presentation/pages/workouts_per_week_page.dart';
import 'package:lifting_tracker_app/core/theme/app_colors.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingShell extends StatefulWidget {
  const OnboardingShell({super.key});

  @override
  State<OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends State<OnboardingShell> {
  final controller = PageController(initialPage: 0);
  int _currentPage = 0;

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'Profile Setup',
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        automaticallyImplyLeading: false,
        leading: _currentPage == 0
            ? null
            : IconButton(
                onPressed: () {
                  controller.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                icon: Icon(Icons.arrow_back_ios_new),
              ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s20),
              child: PageView(
                physics: NeverScrollableScrollPhysics(),
                controller: controller,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  WorkoutsPerWeekPage(controller),
                  SelectSplitPage(controller),
                  PickExercisesPage(controller),
                  ProtectYourProgressPage(),
                ],
              ),
            ),

            Container(
              alignment: Alignment.topCenter,
              child: SmoothPageIndicator(
                controller: controller,
                count: 4,
                effect: SlideEffect(
                  dotWidth: (screenWidth / 4) - 18,
                  dotHeight: 4,
                  spacing: 8,
                  dotColor: AppColors.surface,
                  activeDotColor: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
