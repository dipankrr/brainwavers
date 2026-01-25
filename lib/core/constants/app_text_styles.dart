import 'package:flutter/material.dart';

class AppTextStyles {
  static TextStyle headlineLarge(BuildContext context) {
    return TextStyle(
      fontSize: _responsiveSize(context, 28, 32, 36),
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );
  }

  static TextStyle headlineMedium(BuildContext context) {
    return TextStyle(
      fontSize: _responsiveSize(context, 24, 28, 32),
      fontWeight: FontWeight.w600,
      color: Colors.black,
    );
  }

  static TextStyle titleLarge(BuildContext context) {
    return TextStyle(
      fontSize: _responsiveSize(context, 18, 20, 22),
      fontWeight: FontWeight.w600,
      color: Colors.black,
    );
  }

  static TextStyle bodyLarge(BuildContext context) {
    return TextStyle(
      fontSize: _responsiveSize(context, 16, 18, 20),
      color: Colors.black87,
    );
  }

  static TextStyle bodyMedium(BuildContext context) {
    return TextStyle(
      fontSize: _responsiveSize(context, 14, 16, 18),
      color: Colors.black87,
    );
  }
  static TextStyle bodySmallCustom(BuildContext context) {
    return TextStyle(
      fontSize: _responsiveSize(context, 12, 14, 16),
      color: Colors.black87,
    );
  }

  static double _responsiveSize(BuildContext context, double mobile, double tablet, double desktop) {
    final width = MediaQuery.of(context).size.width;
    if (width < 768) return mobile;
    if (width < 1024) return tablet;
    return desktop;
  }
}