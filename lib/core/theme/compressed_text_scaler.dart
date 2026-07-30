import 'package:flutter/material.dart';

@immutable
final class CompressedTextScaler extends TextScaler {
  const CompressedTextScaler({
    required this.delegate,
    this.compression = 0.4,
    this.minScaleFactor = 1.0,
    this.maxScaleFactor = 1.15,
  });

  final TextScaler delegate;
  final double compression;
  final double minScaleFactor;
  final double maxScaleFactor;

  @override
  double scale(double fontSize) {
    final systemFontSize = delegate.scale(fontSize);

    final compressedFontSize =
        fontSize + (systemFontSize - fontSize) * compression;

    return compressedFontSize
        .clamp(fontSize * minScaleFactor, fontSize * maxScaleFactor)
        .toDouble();
  }

  @override
  double get textScaleFactor => scale(1.0);

  @override
  bool operator ==(Object other) {
    return other is CompressedTextScaler &&
        other.delegate == delegate &&
        other.compression == compression &&
        other.minScaleFactor == minScaleFactor &&
        other.maxScaleFactor == maxScaleFactor;
  }

  @override
  int get hashCode =>
      Object.hash(delegate, compression, minScaleFactor, maxScaleFactor);
}
