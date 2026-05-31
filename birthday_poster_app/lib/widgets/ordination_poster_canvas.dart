import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/poster_data.dart';
import '../services/background_dimensions.dart';
import '../theme/app_theme.dart';
import '../theme/poster_typography.dart';
import '../utils/poster_text_fitter.dart';

/// Measured overlay positions for the 1122×1402 ordination template.
abstract final class OrdinationLayoutConstants {
  static const dateLeft = 2.4;
  static const dateTop = 3.6;

  static const photoLeft = 12.8;
  static const photoTop = 29.8;
  static const photoWidth = 31.5;
  static const photoHeight = 21.5;

  static const infoLeft = 50.2;
  static const infoTop = 29.6;
  static const infoWidth = 35.5;
  static const infoMaxHeight = 14.0;

  static const designationEm = 1.55;
  static const givenEm = 2.35;
  static const roleTitleEm = 1.05;
  static const roleLocationEm = 0.95;
  static const nameRoleGapEm = 0.9;
  static const nameLineGapEm = 0.12;
}

class OrdinationPosterLayout {
  const OrdinationPosterLayout(this.width, this.height);

  final double width;
  final double height;

  static const fallbackAspectRatio = 1122 / 1402;

  double get em => width / 48;

  double xPct(double percent) => width * percent / 100;
  double yPct(double percent) => height * percent / 100;
}

class OrdinationPosterCanvas extends StatelessWidget {
  const OrdinationPosterCanvas({
    super.key,
    required this.data,
    this.photoBytes,
    this.customBackground,
    this.aspectRatio = OrdinationPosterLayout.fallbackAspectRatio,
    this.showShadow = true,
  });

  final PosterData data;
  final Uint8List? photoBytes;
  final ImageProvider? customBackground;
  final double aspectRatio;
  final bool showShadow;

  ImageProvider get _backgroundImage => customBackground ??
      const AssetImage('assets/ordination_poster_background.png');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = fitPosterSize(constraints, aspectRatio);
        final width = size.width;
        final height = size.height;
        final layout = OrdinationPosterLayout(width, height);

        return SizedBox(
          width: width,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3EA),
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
                _OrdinationDateBadge(parsed: data.parsedDate, layout: layout),
                _OrdinationPhotoFrame(
                  layout: layout,
                  photoBytes: photoBytes,
                  data: data,
                ),
                _OrdinationGoldenPanel(data: data, layout: layout),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrdinationDateBadge extends StatelessWidget {
  const _OrdinationDateBadge({required this.parsed, required this.layout});

  final ({String month, String day}) parsed;
  final OrdinationPosterLayout layout;

  @override
  Widget build(BuildContext context) {
    final textStyle = PosterTypography.barlowCondensedDate(
      fontSize: layout.em * 3.1,
      letterSpacing: layout.em * 0.02,
    ).copyWith(color: AppColors.ordinationDateText);
    final month = parsed.month.toUpperCase();
    final day = parsed.day.toUpperCase();

    return Positioned(
      left: layout.xPct(OrdinationLayoutConstants.dateLeft),
      top: layout.yPct(OrdinationLayoutConstants.dateTop),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: layout.xPct(28)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.ordinationDateBadge,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(layout.em * 0.55),
              bottomRight: Radius.circular(layout.em * 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              layout.em * 0.55,
              layout.em * 0.4,
              layout.em * 0.85,
              layout.em * 0.36,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(month, style: textStyle),
                if (day.isNotEmpty) ...[
                  SizedBox(width: layout.em * 0.62),
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

class _OrdinationPhotoFrame extends StatelessWidget {
  const _OrdinationPhotoFrame({
    required this.layout,
    required this.photoBytes,
    required this.data,
  });

  final OrdinationPosterLayout layout;
  final Uint8List? photoBytes;
  final PosterData data;

  @override
  Widget build(BuildContext context) {
    if (photoBytes == null) return const SizedBox.shrink();

    final photoRadius = scaledCssPx(layout.width, 18);

    return Positioned(
      left: layout.xPct(OrdinationLayoutConstants.photoLeft),
      top: layout.yPct(OrdinationLayoutConstants.photoTop),
      width: layout.xPct(OrdinationLayoutConstants.photoWidth),
      height: layout.yPct(OrdinationLayoutConstants.photoHeight),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(photoRadius),
        clipBehavior: Clip.antiAlias,
        child: _OrdinationPositionedPhoto(
          bytes: photoBytes!,
          posX: data.photoPosX,
          posY: data.photoPosY,
          zoom: data.photoZoom,
        ),
      ),
    );
  }
}

class _OrdinationPositionedPhoto extends StatefulWidget {
  const _OrdinationPositionedPhoto({
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
  State<_OrdinationPositionedPhoto> createState() =>
      _OrdinationPositionedPhotoState();
}

class _OrdinationPositionedPhotoState extends State<_OrdinationPositionedPhoto> {
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _decodeImageSize();
  }

  @override
  void didUpdateWidget(_OrdinationPositionedPhoto oldWidget) {
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
            child: Image.memory(
              widget.bytes,
              fit: BoxFit.cover,
              alignment: alignment,
              width: cw,
              height: ch,
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

class _OrdinationGoldenPanel extends StatelessWidget {
  const _OrdinationGoldenPanel({required this.data, required this.layout});

  final PosterData data;
  final OrdinationPosterLayout layout;

  @override
  Widget build(BuildContext context) {
    final blockLeft = layout.xPct(OrdinationLayoutConstants.infoLeft);
    final blockTop = layout.yPct(OrdinationLayoutConstants.infoTop);
    final blockWidth = layout.xPct(OrdinationLayoutConstants.infoWidth);
    final familyWidth = blockWidth * 0.72;

    final designationText =
        data.designation.trim().isEmpty ? ' ' : data.designation.trim();
    final givenText =
        data.givenName.trim().isEmpty ? ' ' : data.givenName.trim().toUpperCase();
    final familyText =
        data.familyName.trim().isEmpty ? ' ' : data.familyName.trim();

    final designationStyle = PosterTypography.montserrat(
      weight: FontWeight.w600,
      fontSize: layout.em * OrdinationLayoutConstants.designationEm,
      height: 1.2,
      color: AppColors.ordinationNameDark,
    );
    final givenStyle = PosterTypography.montserrat(
      weight: FontWeight.w900,
      fontSize: layout.em * OrdinationLayoutConstants.givenEm,
      height: 1.05,
      letterSpacing: layout.em * 0.015,
      color: AppColors.ordinationNameDark,
    );
    final familyStyle = PosterTypography.greatVibes(
      fontSize: layout.em * data.familyFontSize,
      color: AppColors.ordinationNameDark,
    );

    final nameFit = PosterTextFitter.fitNameBlock(
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

    final positions = data.visiblePositions;
    final entries = positions
        .map((p) => (title: p.title.trim(), location: p.location.trim()))
        .toList();

    TextStyle styleFor(double fontSize, {required bool isTitle}) {
      if (isTitle) {
        return PosterTypography.montserrat(
          weight: FontWeight.w800,
          fontSize: fontSize,
          height: 1.15,
          color: AppColors.ordinationNameDark,
        );
      }
      return PosterTypography.montserrat(
        weight: FontWeight.w500,
        fontSize: fontSize,
        height: 1.25,
        color: AppColors.ordinationRoleMuted,
      );
    }

    RolesFitResult? rolesFit;
    if (entries.isNotEmpty) {
      final nameColumnHeight = _estimateNameColumnHeight(
        layout: layout,
        designationText: designationText,
        givenText: givenText,
        familyText: familyText,
        nameFit: nameFit,
        designationStyle: designationStyle,
        givenStyle: givenStyle,
        familyStyle: familyStyle,
        blockWidth: blockWidth,
        familyWidth: familyWidth,
      );

      final rolesBoxTop = blockTop + nameColumnHeight + layout.em * OrdinationLayoutConstants.nameRoleGapEm;
      final rolesBoxHeight = layout.yPct(OrdinationLayoutConstants.infoMaxHeight);
      final initialScale =
          data.roleScaleForCount(entries.length) * data.rolesTextScale;

      rolesFit = PosterTextFitter.fitRolesBlock(
        entries: entries,
        em: layout.em,
        initialScale: initialScale,
        boxWidth: blockWidth * (data.rolesWidth / OrdinationLayoutConstants.infoWidth),
        boxHeight: rolesBoxHeight,
        boxTop: rolesBoxTop,
        posterHeight: layout.height,
        styleFor: styleFor,
      );
    }

    return Positioned(
      left: blockLeft,
      top: blockTop,
      width: blockWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            designationText,
            style: designationStyle.copyWith(fontSize: nameFit.designationSize),
            maxLines: 1,
            softWrap: false,
          ),
          SizedBox(height: layout.em * OrdinationLayoutConstants.nameLineGapEm),
          Text(
            givenText,
            style: givenStyle.copyWith(fontSize: nameFit.givenSize),
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
              child: Text(
                familyText,
                style: familyStyle.copyWith(fontSize: nameFit.familySize),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
          if (entries.isNotEmpty && rolesFit != null) ...[
            SizedBox(height: layout.em * OrdinationLayoutConstants.nameRoleGapEm),
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) SizedBox(height: layout.em * 0.22),
              _OrdinationRoleEntry(
                title: entries[i].title,
                location: entries[i].location,
                titleSize: rolesFit.titleSizes[i],
                locationSize: rolesFit.locationSizes[i],
                entryGap: layout.em * 0.06,
                styleFor: styleFor,
              ),
            ],
          ],
        ],
      ),
    );
  }

  double _estimateNameColumnHeight({
    required OrdinationPosterLayout layout,
    required String designationText,
    required String givenText,
    required String familyText,
    required NameFitResult nameFit,
    required TextStyle designationStyle,
    required TextStyle givenStyle,
    required TextStyle familyStyle,
    required double blockWidth,
    required double familyWidth,
  }) {
    var height = 0.0;

    void addLine(String text, TextStyle style, double size) {
      if (text.trim().isEmpty) return;
      final painter = TextPainter(
        text: TextSpan(text: text, style: style.copyWith(fontSize: size)),
        maxLines: 1,
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: blockWidth);
      height += painter.height;
    }

    addLine(designationText, designationStyle, nameFit.designationSize);
    height += layout.em * OrdinationLayoutConstants.nameLineGapEm;
    addLine(givenText, givenStyle, nameFit.givenSize);
    height += layout.em * data.familyOffsetY;
    if (familyText.trim().isNotEmpty) {
      final painter = TextPainter(
        text: TextSpan(
          text: familyText,
          style: familyStyle.copyWith(fontSize: nameFit.familySize),
        ),
        maxLines: 1,
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: familyWidth);
      height += painter.height;
    }

    return height;
  }
}

class _OrdinationRoleEntry extends StatelessWidget {
  const _OrdinationRoleEntry({
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
