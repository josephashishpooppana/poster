import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Bundled poster fonts (offline — no network fetch).
abstract final class PosterTypography {
  static const montserrat = 'Montserrat';
  static const barlowCondensed = 'Barlow Condensed';
  static const greatVibes = 'Great Vibes';

  static TextStyle barlowCondensedDate({
    required double fontSize,
    required double letterSpacing,
  }) {
    return TextStyle(
      fontFamily: barlowCondensed,
      fontWeight: FontWeight.w800,
      fontSize: fontSize,
      height: 1,
      letterSpacing: letterSpacing,
      color: AppColors.dateText,
    );
  }

  static TextStyle montserrat({
    required FontWeight weight,
    required double fontSize,
    required Color color,
    double height = 1.2,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: montserrat,
      fontWeight: weight,
      fontSize: fontSize,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle greatVibes({
    required double fontSize,
    Color color = AppColors.nameDark,
  }) {
    return TextStyle(
      fontFamily: greatVibes,
      fontSize: fontSize,
      height: 1.2,
      color: color,
    );
  }
}

/// Scales fixed HTML css px (at 540px preview width) to current poster size.
double scaledCssPx(double posterWidth, double cssPx) =>
    cssPx * (posterWidth / 540);
