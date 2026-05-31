import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/poster_data.dart';
import '../theme/app_theme.dart';

/// Poster template is 1280×1600 (4∶5). All overlay positions match index.html CSS
/// percentages: horizontal values use poster width, vertical values use height.
class PosterLayout {
  const PosterLayout(this.width, this.height);

  final double width;
  final double height;

  static const templateAspectRatio = 1280 / 1600;

  /// Matches HTML `font-size: width / 48` on `.poster`.
  double get em => width / 48;

  double xPct(double percent) => width * percent / 100;
  double yPct(double percent) => height * percent / 100;
}

class PosterCanvas extends StatelessWidget {
  const PosterCanvas({
    super.key,
    required this.data,
    this.photoBytes,
    this.customBackground,
  });

  final PosterData data;
  final Uint8List? photoBytes;
  final ImageProvider? customBackground;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width / PosterLayout.templateAspectRatio;
        final layout = PosterLayout(width, height);

        return SizedBox(
          width: width,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F0),
              image: DecorationImage(
                image: customBackground ??
                    const AssetImage('assets/poster_background.jpeg'),
                fit: BoxFit.fill,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _DateBadge(parsed: data.parsedDate, layout: layout),
                _PhotoFrame(
                  layout: layout,
                  photoBytes: photoBytes,
                  data: data,
                ),
                _NameBlock(data: data, layout: layout),
                _RolesBlock(data: data, layout: layout),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.parsed, required this.layout});

  final ({String month, String day}) parsed;
  final PosterLayout layout;

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.barlowCondensed(
      fontWeight: FontWeight.w800,
      fontSize: layout.em * 3.4,
      height: 1,
      letterSpacing: 0.5,
      color: AppColors.dateText,
    );

    return Positioned(
      left: layout.xPct(0.6),
      top: layout.yPct(5.0),
      child: Container(
        constraints: BoxConstraints(maxWidth: layout.xPct(28)),
        padding: EdgeInsets.fromLTRB(
          layout.em * 0.52,
          layout.em * 0.42,
          layout.em * 0.9,
          layout.em * 0.38,
        ),
        decoration: BoxDecoration(
          color: AppColors.dateBadge,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(layout.em * 0.55),
            bottomRight: Radius.circular(layout.em * 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(parsed.month, style: textStyle),
            if (parsed.day.isNotEmpty) ...[
              SizedBox(width: layout.em * 0.68),
              Text(parsed.day, style: textStyle),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhotoFrame extends StatelessWidget {
  const _PhotoFrame({
    required this.layout,
    required this.photoBytes,
    required this.data,
  });

  final PosterLayout layout;
  final Uint8List? photoBytes;
  final PosterData data;

  @override
  Widget build(BuildContext context) {
    if (photoBytes == null) return const SizedBox.shrink();

    final borderWidth = layout.em * 0.4;
    final cardRadius = layout.em * 2.8;
    final photoRadius = layout.em * 2.4;

    return Stack(
      children: [
        Positioned(
          left: layout.xPct(7.0),
          top: layout.yPct(36.6),
          width: layout.xPct(40.5),
          height: layout.yPct(39.8),
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: borderWidth),
                borderRadius: BorderRadius.circular(cardRadius),
              ),
            ),
          ),
        ),
        Positioned(
          left: layout.xPct(7.4),
          top: layout.yPct(37.0),
          width: layout.xPct(39.7),
          height: layout.yPct(39.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(photoRadius),
            child: _PositionedPhoto(
              bytes: photoBytes!,
              posX: data.photoPosX,
              posY: data.photoPosY,
              zoom: data.photoZoom,
            ),
          ),
        ),
      ],
    );
  }
}

class _PositionedPhoto extends StatelessWidget {
  const _PositionedPhoto({
    required this.bytes,
    required this.posX,
    required this.posY,
    required this.zoom,
  });

  final Uint8List bytes;
  final double posX;
  final double posY;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final alignment = Alignment(
      2 * (posX / 100) - 1,
      2 * (posY / 100) - 1,
    );
    final scale = zoom / 100;
    final imageScale = scale <= 0 ? 1.0 : (scale < 1 ? 1 / scale : scale);

    return SizedBox.expand(
      child: Transform.scale(
        scale: imageScale,
        alignment: alignment,
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          alignment: alignment,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}

class _NameBlock extends StatelessWidget {
  const _NameBlock({required this.data, required this.layout});

  final PosterData data;
  final PosterLayout layout;

  @override
  Widget build(BuildContext context) {
    final blockWidth = layout.xPct(44);

    return Positioned(
      left: layout.xPct(52.0),
      top: layout.yPct(42.4),
      width: blockWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AutoFitText(
            text: data.designation.trim().isEmpty ? ' ' : data.designation.trim(),
            maxWidth: blockWidth,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w500,
              fontSize: layout.em * 1.85,
              height: 1.2,
              color: const Color(0xFF0D2F29),
            ),
          ),
          SizedBox(height: layout.em * 0.25),
          _AutoFitText(
            text: data.givenName.trim().isEmpty ? ' ' : data.givenName.trim().toUpperCase(),
            maxWidth: blockWidth,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w900,
              fontSize: layout.em * 2.85,
              height: 1.05,
              letterSpacing: 0.3,
              color: AppColors.nameDark,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: blockWidth * (data.familyOffsetX / 100),
              top: layout.em * data.familyOffsetY,
            ),
            child: SizedBox(
              width: blockWidth * 0.68,
              child: _AutoFitText(
                text: data.familyName.trim().isEmpty ? ' ' : data.familyName.trim(),
                maxWidth: blockWidth * 0.68,
                style: GoogleFonts.greatVibes(
                  fontSize: layout.em * data.familyFontSize,
                  height: 1.2,
                  color: AppColors.nameDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolesBlock extends StatelessWidget {
  const _RolesBlock({required this.data, required this.layout});

  final PosterData data;
  final PosterLayout layout;

  @override
  Widget build(BuildContext context) {
    final positions = data.visiblePositions;
    if (positions.isEmpty) return const SizedBox.shrink();

    final scale = data.roleScaleForCount(positions.length) * data.rolesTextScale;
    final boxWidth = layout.xPct(data.rolesWidth);
    final boxHeight = layout.yPct(data.rolesHeight);

    final mainAlign = switch (data.rolesAlign) {
      RolesVerticalAlign.top => MainAxisAlignment.start,
      RolesVerticalAlign.center => MainAxisAlignment.center,
      RolesVerticalAlign.bottom => MainAxisAlignment.end,
    };

    return Positioned(
      left: layout.xPct(data.rolesLeft),
      top: layout.yPct(data.rolesTop),
      width: boxWidth,
      height: boxHeight,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          layout.em * 0,
          layout.em * 0.35,
          layout.em * 0.15,
          layout.em * data.rolesPadBottom,
        ),
        child: Column(
          mainAxisAlignment: mainAlign,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < positions.length; i++) ...[
              if (i > 0) SizedBox(height: layout.em * 0.28),
              _RoleEntry(
                position: positions[i],
                layout: layout,
                scale: scale,
                maxWidth: boxWidth,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleEntry extends StatelessWidget {
  const _RoleEntry({
    required this.position,
    required this.layout,
    required this.scale,
    required this.maxWidth,
  });

  final ChurchPosition position;
  final PosterLayout layout;
  final double scale;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (position.title.trim().isNotEmpty)
          _AutoFitText(
            text: position.title.trim(),
            maxWidth: maxWidth,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w800,
              fontSize: layout.em * 1.22 * scale * 1.05,
              height: 1.15,
              color: const Color(0xFF072922),
            ),
          ),
        if (position.location.trim().isNotEmpty)
          _AutoFitText(
            text: position.location.trim(),
            maxWidth: maxWidth,
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w500,
              fontSize: layout.em * 1.05 * scale * 1.05,
              height: 1.25,
              color: AppColors.roleMuted,
            ),
          ),
      ],
    );
  }
}

class _AutoFitText extends StatelessWidget {
  const _AutoFitText({
    required this.text,
    required this.maxWidth,
    required this.style,
  });

  final String text;
  final double maxWidth;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: maxWidth,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: style,
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }
}
