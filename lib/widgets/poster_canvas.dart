import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/poster_data.dart';
import '../theme/app_theme.dart';

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
        final unit = width / 48;

        return AspectRatio(
          aspectRatio: 4 / 5,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F0),
              image: DecorationImage(
                image: customBackground ??
                    const AssetImage('assets/poster_background.jpeg'),
                fit: BoxFit.fill,
                onError: (_, __) {},
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
                _DateBadge(parsed: data.parsedDate, unit: unit),
                _PhotoFrame(unit: unit, photoBytes: photoBytes, data: data),
                _NameBlock(data: data, unit: unit),
                _RolesBlock(data: data, unit: unit),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.parsed, required this.unit});

  final ({String month, String day}) parsed;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.barlowCondensed(
      fontWeight: FontWeight.w800,
      fontSize: unit * 3.4,
      height: 1,
      letterSpacing: 0.5,
      color: AppColors.dateText,
    );

    return Positioned(
      left: unit * 0.29,
      top: unit * 2.4,
      child: Container(
        padding: EdgeInsets.fromLTRB(unit * 0.25, unit * 0.2, unit * 0.43, unit * 0.18),
        decoration: BoxDecoration(
          color: AppColors.dateBadge,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(unit * 0.55),
            bottomRight: Radius.circular(unit * 0.55),
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
              SizedBox(width: unit * 0.33),
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
    required this.unit,
    required this.photoBytes,
    required this.data,
  });

  final double unit;
  final Uint8List? photoBytes;
  final PosterData data;

  @override
  Widget build(BuildContext context) {
    final left = unit * 3.36;
    final top = unit * 17.57;
    final width = unit * 19.44;
    final height = unit * 19.1;
    final innerRadius = unit * 2.4;
    final borderRadius = unit * 2.8;

    return Stack(
      children: [
        Positioned(
          left: left - unit * 0.19,
          top: top - unit * 0.19,
          width: width + unit * 0.38,
          height: height + unit * 0.38,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: unit * 0.38),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(innerRadius),
            child: photoBytes == null
                ? ColoredBox(
                    color: const Color(0xFFE1E7E4),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(unit * 0.5),
                        child: Text(
                          'Add a portrait photo',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            fontSize: unit * 1.1,
                            color: const Color(0xFF55726B),
                          ),
                        ),
                      ),
                    ),
                  )
                : _PositionedPhoto(
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

    return ClipRect(
      child: OverflowBox(
        alignment: alignment,
        minWidth: 0,
        minHeight: 0,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: Transform.scale(
          scale: scale <= 0 ? 1 : (scale < 1 ? 1 / scale : scale),
          alignment: alignment,
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            alignment: alignment,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}

class _NameBlock extends StatelessWidget {
  const _NameBlock({required this.data, required this.unit});

  final PosterData data;
  final double unit;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: unit * 24.96,
      top: unit * 20.35,
      width: unit * 21.12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FitText(
            text: data.designation.trim().isEmpty ? ' ' : data.designation.trim(),
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w500,
              fontSize: unit * 1.85,
              height: 1.2,
              color: const Color(0xFF0D2F29),
            ),
          ),
          _FitText(
            text: data.givenName.trim().isEmpty ? ' ' : data.givenName.trim().toUpperCase(),
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w900,
              fontSize: unit * 2.85,
              height: 1.05,
              letterSpacing: 0.3,
              color: AppColors.nameDark,
            ),
          ),
          Transform.translate(
            offset: Offset(
              unit * 21.12 * (data.familyOffsetX / 100),
              unit * data.familyOffsetY,
            ),
            child: SizedBox(
              width: unit * 21.12 * 0.68,
              child: _FitText(
                text: data.familyName.trim().isEmpty ? ' ' : data.familyName.trim(),
                style: GoogleFonts.greatVibes(
                  fontSize: unit * data.familyFontSize,
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
  const _RolesBlock({required this.data, required this.unit});

  final PosterData data;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final positions = data.visiblePositions;
    if (positions.isEmpty) return const SizedBox.shrink();

    final scale = data.roleScaleForCount(positions.length) * data.rolesTextScale;
    final mainAlign = switch (data.rolesAlign) {
      RolesVerticalAlign.top => MainAxisAlignment.start,
      RolesVerticalAlign.center => MainAxisAlignment.center,
      RolesVerticalAlign.bottom => MainAxisAlignment.end,
    };

    return Positioned(
      left: unit * 48 * (data.rolesLeft / 100),
      top: unit * 48 * (data.rolesTop / 100),
      width: unit * 48 * (data.rolesWidth / 100),
      height: unit * 48 * (data.rolesHeight / 100),
      child: Padding(
        padding: EdgeInsets.only(bottom: unit * data.rolesPadBottom),
        child: Column(
          mainAxisAlignment: mainAlign,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final pos in positions) ...[
              _RoleEntry(position: pos, unit: unit, scale: scale),
              SizedBox(height: unit * 0.28),
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
    required this.unit,
    required this.scale,
  });

  final ChurchPosition position;
  final double unit;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (position.title.trim().isNotEmpty)
          _FitText(
            text: position.title.trim(),
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w800,
              fontSize: unit * 1.22 * scale * 1.05,
              height: 1.15,
              color: const Color(0xFF072922),
            ),
          ),
        if (position.location.trim().isNotEmpty)
          _FitText(
            text: position.location.trim(),
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w500,
              fontSize: unit * 1.05 * scale * 1.05,
              height: 1.25,
              color: AppColors.roleMuted,
            ),
          ),
      ],
    );
  }
}

class _FitText extends StatelessWidget {
  const _FitText({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text, style: style, maxLines: 1),
    );
  }
}
