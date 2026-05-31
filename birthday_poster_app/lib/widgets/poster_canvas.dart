import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/poster_data.dart';
import '../services/background_dimensions.dart';
import '../theme/app_theme.dart';
import '../theme/poster_typography.dart';
import '../utils/poster_text_fitter.dart';

/// All overlay positions match index.html CSS percentages: horizontal values
/// use poster width, vertical values use height.
class PosterLayout {
  const PosterLayout(this.width, this.height);

  final double width;
  final double height;

  static const fallbackAspectRatio = 1280 / 1600;

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
    this.aspectRatio = PosterLayout.fallbackAspectRatio,
    this.showShadow = true,
  });

  final PosterData data;
  final Uint8List? photoBytes;
  final ImageProvider? customBackground;
  final double aspectRatio;
  final bool showShadow;

  ImageProvider get _backgroundImage =>
      customBackground ?? const AssetImage('assets/poster_background.jpeg');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = fitPosterSize(constraints, aspectRatio);
        final width = size.width;
        final height = size.height;
        final layout = PosterLayout(width, height);

        return SizedBox(
          width: width,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F0),
              image: DecorationImage(
                image: _backgroundImage,
                fit: BoxFit.fill,
              ),
              boxShadow: showShadow
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
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
    final textStyle = PosterTypography.barlowCondensedDate(
      fontSize: layout.em * 3.4,
      letterSpacing: layout.em * 0.03,
    );
    final month = parsed.month.toUpperCase();
    final day = parsed.day.toUpperCase();

    return Positioned(
      left: layout.xPct(0.6),
      top: layout.yPct(5.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: layout.xPct(28)),
        child: DecoratedBox(
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
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              layout.em * 0.52,
              layout.em * 0.42,
              layout.em * 0.9,
              layout.em * 0.38,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(month, style: textStyle),
                if (day.isNotEmpty) ...[
                  SizedBox(width: layout.em * 0.68),
                  Text(day, style: textStyle),
                ],
              ],
            ),
          ),
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

    final borderWidth = scaledCssPx(layout.width, 4);
    final cardRadius = scaledCssPx(layout.width, 28);
    final photoRadius = scaledCssPx(layout.width, 24);

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
            clipBehavior: Clip.antiAlias,
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

class _PositionedPhoto extends StatefulWidget {
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
  State<_PositionedPhoto> createState() => _PositionedPhotoState();
}

class _PositionedPhotoState extends State<_PositionedPhoto> {
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _decodeImageSize();
  }

  @override
  void didUpdateWidget(_PositionedPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bytes != widget.bytes) {
      _decodeImageSize();
    }
  }

  Future<void> _decodeImageSize() async {
    final codec = await ui.instantiateImageCodec(widget.bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) {
      frame.image.dispose();
      return;
    }
    setState(() {
      _imageSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
    });
    frame.image.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alignment = Alignment(
      2 * (widget.posX / 100) - 1,
      2 * (widget.posY / 100) - 1,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final cw = constraints.maxWidth;
        final ch = constraints.maxHeight;

        if (_imageSize == null) {
          return SizedBox(
            width: cw,
            height: ch,
            child: ColoredBox(
              color: const Color(0xFFE1E7E4),
              child: Image.memory(
                widget.bytes,
                fit: BoxFit.cover,
                alignment: alignment,
                width: cw,
                height: ch,
              ),
            ),
          );
        }

        if (widget.zoom == 100) {
          return SizedBox(
            width: cw,
            height: ch,
            child: Image.memory(
              widget.bytes,
              fit: BoxFit.cover,
              alignment: alignment,
              width: cw,
              height: ch,
            ),
          );
        }

        // Matches CSS: background-size: zoom%; background-position: posX% posY%
        final z = widget.zoom / 100;
        final imgW = cw * z;
        final imgH = imgW * (_imageSize!.height / _imageSize!.width);
        final left = (widget.posX / 100) * (cw - imgW);
        final top = (widget.posY / 100) * (ch - imgH);

        return SizedBox(
          width: cw,
          height: ch,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: left,
                top: top,
                width: imgW,
                height: imgH,
                child: Image.memory(
                  widget.bytes,
                  fit: BoxFit.fill,
                  width: imgW,
                  height: imgH,
                ),
              ),
            ],
          ),
        );
      },
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
    final blockLeft = layout.xPct(52.0);
    final familyWidth = blockWidth * 0.68;

    final designationText =
        data.designation.trim().isEmpty ? ' ' : data.designation.trim();
    final givenText =
        data.givenName.trim().isEmpty ? ' ' : data.givenName.trim().toUpperCase();
    final familyText =
        data.familyName.trim().isEmpty ? ' ' : data.familyName.trim();

    final designationStyle = PosterTypography.montserrat(
      weight: FontWeight.w500,
      fontSize: layout.em * 1.85,
      height: 1.2,
      color: const Color(0xFF0D2F29),
    );
    final givenStyle = PosterTypography.montserrat(
      weight: FontWeight.w900,
      fontSize: layout.em * 2.85,
      height: 1.05,
      letterSpacing: layout.em * 0.02,
      color: AppColors.nameDark,
    );
    final familyStyle = PosterTypography.greatVibes(
      fontSize: layout.em * data.familyFontSize,
    );

    final fit = PosterTextFitter.fitNameBlock(
      designation: designationText,
      given: givenText,
      family: familyText,
      designationStyle: designationStyle,
      givenStyle: givenStyle,
      familyStyle: familyStyle,
      designationMaxWidth: blockWidth,
      givenMaxWidth: blockWidth,
      familyMaxWidth: familyWidth,
      blockLeft: blockLeft,
      familyOffsetX: data.familyOffsetX,
      posterWidth: layout.width,
    );

    return Positioned(
      left: blockLeft,
      top: layout.yPct(42.4),
      width: blockWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            designationText,
            style: designationStyle.copyWith(fontSize: fit.designationSize),
            maxLines: 1,
            softWrap: false,
          ),
          SizedBox(height: layout.em * 0.25),
          Text(
            givenText,
            style: givenStyle.copyWith(fontSize: fit.givenSize),
            maxLines: 1,
            softWrap: false,
          ),
          Padding(
            padding: EdgeInsets.only(
              left: blockWidth * (data.familyOffsetX / 100),
              top: layout.em * data.familyOffsetY,
            ),
            child: SizedBox(
              width: familyWidth,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  layout.em * 0.14,
                  layout.em * 0.22,
                  layout.em * 0.2,
                  layout.em * 0.32,
                ),
                child: Text(
                  familyText,
                  style: familyStyle.copyWith(fontSize: fit.familySize),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
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

    final boxWidth = layout.xPct(data.rolesWidth);
    final boxHeight = layout.yPct(data.rolesHeight);
    final boxTop = layout.yPct(data.rolesTop);
    final initialScale =
        data.roleScaleForCount(positions.length) * data.rolesTextScale;

    final entries = positions
        .map(
          (p) => (
            title: p.title.trim(),
            location: p.location.trim(),
          ),
        )
        .toList();

    TextStyle styleFor(double fontSize, {required bool isTitle}) {
      if (isTitle) {
        return PosterTypography.montserrat(
          weight: FontWeight.w800,
          fontSize: fontSize,
          height: 1.15,
          color: const Color(0xFF072922),
        );
      }
      return PosterTypography.montserrat(
        weight: FontWeight.w500,
        fontSize: fontSize,
        height: 1.25,
        color: AppColors.roleMuted,
      );
    }

    final fit = PosterTextFitter.fitRolesBlock(
      entries: entries,
      em: layout.em,
      initialScale: initialScale,
      boxWidth: boxWidth,
      boxHeight: boxHeight,
      boxTop: boxTop,
      posterHeight: layout.height,
      styleFor: styleFor,
    );

    final mainAlign = switch (data.rolesAlign) {
      RolesVerticalAlign.top => MainAxisAlignment.start,
      RolesVerticalAlign.center => MainAxisAlignment.center,
      RolesVerticalAlign.bottom => MainAxisAlignment.end,
    };

    return Positioned(
      left: layout.xPct(data.rolesLeft),
      top: boxTop,
      width: boxWidth,
      height: boxHeight,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          0,
          layout.em * 0.35,
          layout.em * 0.15,
          layout.em * data.rolesPadBottom,
        ),
        child: Column(
          mainAxisAlignment: mainAlign,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) SizedBox(height: layout.em * 0.28),
              _RoleEntry(
                title: entries[i].title,
                location: entries[i].location,
                titleSize: fit.titleSizes[i],
                locationSize: fit.locationSizes[i],
                entryGap: layout.em * 0.08,
                styleFor: styleFor,
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
    required this.title,
    required this.location,
    required this.titleSize,
    required this.locationSize,
    required this.entryGap,
    required this.styleFor,
  });

  final String title;
  final String location;
  final double titleSize;
  final double locationSize;
  final double entryGap;
  final TextStyle Function(double fontSize, {required bool isTitle}) styleFor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Text(
            title,
            style: styleFor(titleSize, isTitle: true),
            maxLines: 1,
            softWrap: false,
          ),
        if (location.isNotEmpty) ...[
          if (title.isNotEmpty) SizedBox(height: entryGap),
          Text(
            location,
            style: styleFor(locationSize, isTitle: false),
            maxLines: 1,
            softWrap: false,
          ),
        ],
      ],
    );
  }
}
