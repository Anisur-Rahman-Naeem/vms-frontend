import 'package:flutter/material.dart';

/// Responsive helper for desktop-first layouts with tablet, mobile, and 4K/8K ultra-wide adaptations.
class Responsive extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  final Widget? ultraWide;

  const Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.ultraWide,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 768;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= 768 && width < 1100;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1100;

  static bool isUltraWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 2560;

  static bool is4K(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 3840;

  static bool is8K(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 6000;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 2560 && ultraWide != null) {
      return ultraWide!;
    } else if (width >= 1100) {
      return desktop;
    } else if (width >= 768 && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}

