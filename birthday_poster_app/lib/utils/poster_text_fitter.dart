import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Text fitting utilities ported from index.html fitElement / fitNameBlock /
/// fitRolesBlock.
class PosterTextFitter {
  /// Iteratively shrinks [baseFontSize] until [text] fits [maxWidth].
  static double fitElement({
    required String text,
    required TextStyle style,
    required double maxWidth,
    double minRatio = 0.45,
  }) {
    final def = style.fontSize ?? 16;
    final minSize = def * minRatio;
    var size = def;

    for (var i = 0; i < 60 && size > minSize; i++) {
      if (!_overflows(text, style.copyWith(fontSize: size), maxWidth)) {
        break;
      }
      size -= math.max(0.25, def * 0.025);
    }
    return size;
  }

  static bool _overflows(String text, TextStyle style, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: double.infinity);
    return painter.width > maxWidth + 1;
  }

  static double _textWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  /// Fits designation, given, and family names; group-shrinks when overflowing
  /// the poster right edge (matches HTML fitNameBlock).
  static NameFitResult fitNameBlock({
    required String designation,
    required String given,
    required String family,
    required TextStyle designationStyle,
    required TextStyle givenStyle,
    required TextStyle familyStyle,
    required double designationMaxWidth,
    required double givenMaxWidth,
    required double familyMaxWidth,
    required double blockLeft,
    required double familyOffsetX,
    required double posterWidth,
  }) {
    var desSize = fitElement(
      text: designation,
      style: designationStyle,
      maxWidth: designationMaxWidth,
      minRatio: 0.4,
    );
    var givenSize = fitElement(
      text: given,
      style: givenStyle,
      maxWidth: givenMaxWidth,
      minRatio: 0.4,
    );
    var familySize = fitElement(
      text: family,
      style: familyStyle,
      maxWidth: familyMaxWidth,
      minRatio: 0.35,
    );

    var groupScale = 1.0;
    for (var guard = 0; guard < 30; guard++) {
      final desStyle = designationStyle.copyWith(fontSize: desSize * groupScale);
      final givenStyleScaled = givenStyle.copyWith(fontSize: givenSize * groupScale);
      final familyStyleScaled = familyStyle.copyWith(fontSize: familySize * groupScale);

      final familyLeft = blockLeft + givenMaxWidth * (familyOffsetX / 100);
      final posterRight = posterWidth - 3;

      var overflow = false;
      if (blockLeft + _textWidth(designation, desStyle) > posterRight) {
        overflow = true;
      }
      if (blockLeft + _textWidth(given, givenStyleScaled) > posterRight) {
        overflow = true;
      }
      if (familyLeft + _textWidth(family, familyStyleScaled) > posterRight) {
        overflow = true;
      }

      if (!overflow) break;

      groupScale -= 0.04;
      if (groupScale < 0.35) break;
    }

    return NameFitResult(
      designationSize: desSize * groupScale,
      givenSize: givenSize * groupScale,
      familySize: familySize * groupScale,
    );
  }

  /// Fits role entries; dynamically reduces scale when content overflows
  /// (matches HTML fitRolesBlock).
  static RolesFitResult fitRolesBlock({
    required List<({String title, String location})> entries,
    required double em,
    required double initialScale,
    required double boxWidth,
    required double boxHeight,
    required double boxTop,
    required double posterHeight,
    required TextStyle Function(double fontSize, {required bool isTitle}) styleFor,
    double titleEm = 1.22,
    double locationEm = 1.05,
    double gapEm = 0.28,
    double entryGapEm = 0.08,
    double padTopEm = 0.35,
    double padBottomEm = 0,
    double? nameBlockHeight,
  }) {
    var scale = initialScale;
    final titleBase = em * titleEm;
    final locationBase = em * locationEm;
    final gap = em * gapEm;
    final padTop = em * padTopEm;
    final entryGap = em * entryGapEm;
    final padBottom = em * padBottomEm;
    final maxBottom = posterHeight * 0.855;

    List<double> titleSizes = [];
    List<double> locationSizes = [];

    for (var guard = 0; guard < 40; guard++) {
      titleSizes = [];
      locationSizes = [];

      for (final entry in entries) {
        if (entry.title.isNotEmpty) {
          titleSizes.add(
            fitElement(
              text: entry.title,
              style: styleFor(titleBase * scale, isTitle: true),
              maxWidth: boxWidth,
              minRatio: scale < 0.45 ? 0.35 : 0.4,
            ),
          );
        } else {
          titleSizes.add(0);
        }
        if (entry.location.isNotEmpty) {
          locationSizes.add(
            fitElement(
              text: entry.location,
              style: styleFor(locationBase * scale, isTitle: false),
              maxWidth: boxWidth,
              minRatio: scale < 0.45 ? 0.35 : 0.4,
            ),
          );
        } else {
          locationSizes.add(0);
        }
      }

      var contentHeight = padTop;
      for (var i = 0; i < entries.length; i++) {
        if (i > 0) contentHeight += gap;
        if (entries[i].title.isNotEmpty) {
          contentHeight += _lineHeight(
            entries[i].title,
            styleFor(titleSizes[i], isTitle: true),
          );
        }
        if (entries[i].location.isNotEmpty) {
          if (entries[i].title.isNotEmpty) contentHeight += entryGap;
          contentHeight += _lineHeight(
            entries[i].location,
            styleFor(locationSizes[i], isTitle: false),
          );
        }
      }

      final horizontalOverflow = _rolesHorizontalOverflow(
        entries: entries,
        titleSizes: titleSizes,
        locationSizes: locationSizes,
        boxWidth: boxWidth,
        styleFor: styleFor,
      );
      final verticalOverflow = nameBlockHeight != null
          ? nameBlockHeight + contentHeight + padBottom > boxHeight + 2
          : boxTop + contentHeight > maxBottom + 1 ||
              contentHeight > boxHeight + 2;

      if (!horizontalOverflow && !verticalOverflow) break;

      scale -= 0.04;
      if (scale < 0.45) {
        scale = math.max(0.45, scale);
        titleSizes = [];
        locationSizes = [];
        for (final entry in entries) {
          if (entry.title.isNotEmpty) {
            titleSizes.add(
              fitElement(
                text: entry.title,
                style: styleFor(titleBase * scale, isTitle: true),
                maxWidth: boxWidth,
                minRatio: 0.35,
              ),
            );
          } else {
            titleSizes.add(0);
          }
          if (entry.location.isNotEmpty) {
            locationSizes.add(
              fitElement(
                text: entry.location,
                style: styleFor(locationBase * scale, isTitle: false),
                maxWidth: boxWidth,
                minRatio: 0.35,
              ),
            );
          } else {
            locationSizes.add(0);
          }
        }
        break;
      }
    }

    return RolesFitResult(
      roleScale: scale,
      titleSizes: titleSizes,
      locationSizes: locationSizes,
    );
  }

  static bool _rolesHorizontalOverflow({
    required List<({String title, String location})> entries,
    required List<double> titleSizes,
    required List<double> locationSizes,
    required double boxWidth,
    required TextStyle Function(double fontSize, {required bool isTitle}) styleFor,
  }) {
    for (var i = 0; i < entries.length; i++) {
      if (entries[i].title.isNotEmpty &&
          _textWidth(
                entries[i].title,
                styleFor(titleSizes[i], isTitle: true),
              ) >
              boxWidth + 1) {
        return true;
      }
      if (entries[i].location.isNotEmpty &&
          _textWidth(
                entries[i].location,
                styleFor(locationSizes[i], isTitle: false),
              ) >
              boxWidth + 1) {
        return true;
      }
    }
    return false;
  }

  static double _lineHeight(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    )..layout();
    return painter.height;
  }
}

class NameFitResult {
  const NameFitResult({
    required this.designationSize,
    required this.givenSize,
    required this.familySize,
  });

  final double designationSize;
  final double givenSize;
  final double familySize;
}

class RolesFitResult {
  const RolesFitResult({
    required this.roleScale,
    required this.titleSizes,
    required this.locationSizes,
  });

  final double roleScale;
  final List<double> titleSizes;
  final List<double> locationSizes;
}
