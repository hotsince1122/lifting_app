import 'package:flutter/material.dart';
import 'package:lifting_tracker_app/models/gradient_variants.dart';
import 'package:lifting_tracker_app/theme/app_colors.dart';
import 'package:lifting_tracker_app/widgets/gradient_button.dart';

import 'package:lifting_tracker_app/widgets/gradient_cards.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage(this.controller, {super.key});

  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 46),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 80,
            child: GradientCard(
              gradientVariant: Gradients.of(GradientVariant.darkOne),
              child: Center(
                child: Text(
                  'Welcome to Focus Lifts',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: GradientCard(
              gradientVariant: Gradients.of(GradientVariant.darkThree),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset("assets/dumbbell_logo.png", scale: 4, color: AppColors.accentLightWhite,),
                  const SizedBox(height: 8),
                  Text(
                    "Let's make every rep count, together",
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Spacer(),
          GradientButton(
            isActive: false,
            buttonHight: 48,
            onPressed: () => controller.nextPage(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeIn,
            ),
            gradientVariant: Gradients.of(GradientVariant.lightOne),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Get Started',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
