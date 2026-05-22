import 'package:flutter/material.dart';

Route<T> sheetParallaxRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    opaque: true,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Cum intră pagina asta (de sus): din dreapta
      final inCurve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final inSlide = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(inCurve);

      // Cum se mișcă pagina asta când devine "în spate" (când altă pagină e împinsă peste ea)
      final backCurve = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final backSlide = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.20, 0), // puțin spre stânga
      ).animate(backCurve);

      final backScale = Tween<double>(
        begin: 1.0,
        end: 0.98, // ușor "în spate"
      ).animate(backCurve);

      // IMPORTANT: fără Opacity/Fade/Color overlay. Doar transformări.
      return SlideTransition(
        position: backSlide,
        child: ScaleTransition(
          scale: backScale,
          child: SlideTransition(position: inSlide, child: child),
        ),
      );
    },
  );
}