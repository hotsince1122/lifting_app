import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/screens/onboarding_pages/pick_exercises_page.dart';
import 'package:lifting_tracker_app/screens/onboarding_pages/select_split_page.dart';
import 'package:lifting_tracker_app/screens/onboarding_pages/workouts_per_week_page.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
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
        title: Text(
          'Profile Setup',
          style: Theme.of(context).textTheme.headlineSmall,
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
        bottom: false,
        child: Stack(
          children: [
            PageView(
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
              ],
            ),

            Container(
              alignment: Alignment.topCenter,
              child: SmoothPageIndicator(
                controller: controller,
                count: 3,
                effect: SlideEffect(
                  dotWidth: (screenWidth / 3) - 18,
                  dotHeight: 6,
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
