import 'package:flutter/material.dart';

/// Centralized responsive utilities for consistent breakpoint handling
/// and adaptive sizing across the meal planner app.
class ResponsiveUtils {
  // Prevent instantiation
  ResponsiveUtils._();

  // ─────────────────────────────────────────────────────────────────────────
  // Breakpoint Constants (Material Design + Common Devices)
  // ─────────────────────────────────────────────────────────────────────────

  /// Extra small phones (iPhone SE, old Android)
  static const double phoneSmall = 320;

  /// Standard phone (iPhone 12/13, Pixel)
  static const double phoneNormal = 375;

  /// Large phone (iPhone Pro Max, large Android)
  static const double phoneLarge = 414;

  /// Tablet (Material Design breakpoint)
  static const double tablet = 600;

  /// Desktop/Large tablet
  static const double desktop = 1200;

  // ─────────────────────────────────────────────────────────────────────────
  // Screen Size Checks
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns true if screen width is below standard phone size (< 375px)
  static bool isPhoneSmall(BuildContext context) {
    return MediaQuery.of(context).size.width < phoneNormal;
  }

  /// Returns true if screen width is below tablet breakpoint (< 600px)
  static bool isPhone(BuildContext context) {
    return MediaQuery.of(context).size.width < tablet;
  }

  /// Returns true if screen width is in tablet range (600px - 1200px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tablet && width < desktop;
  }

  /// Returns true if screen width is desktop size (>= 1200px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Adaptive Sizing
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns optimal dialog/sheet width based on screen size
  /// - Phone: 90% of screen width
  /// - Tablet: 500px fixed
  /// - Desktop: 600px fixed
  static double dialogWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < tablet) {
      return width * 0.9;
    } else if (width < desktop) {
      return 500;
    } else {
      return 600;
    }
  }

  /// Returns adaptive padding value for outer containers
  /// - Small phones: 8px
  /// - Normal and above: 12px
  static double containerPadding(BuildContext context) {
    return isPhoneSmall(context) ? 8.0 : 12.0;
  }

  /// Returns adaptive field width based on base/small values
  /// Useful for form fields that need different widths on small screens
  static double fieldWidth(
    BuildContext context, {
    required double base,
    required double small,
  }) {
    return isPhoneSmall(context) ? small : base;
  }

  /// Returns minimum width for autocomplete dropdowns (50% of screen, max 400)
  static double autocompleteMinWidth(BuildContext context) {
    return (MediaQuery.of(context).size.width * 0.5).clamp(180.0, 400.0);
  }
}
