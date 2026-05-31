import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'poster_fonts.dart';

class PosterExporter {
  /// Renders [poster] offscreen at [templateWidth] and shares the result.
  static Future<void> exportAndShare({
    required BuildContext context,
    required Widget poster,
    required double templateWidth,
    required String givenName,
    required bool asJpeg,
    double pixelRatio = 2,
  }) async {
    await PosterFonts.ensureLoaded();

    final key = GlobalKey();
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: -templateWidth * 3,
        top: 0,
        child: Material(
          color: Colors.transparent,
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: templateWidth,
              child: poster,
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(entry);

    try {
      await Future<void>.delayed(Duration.zero);
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;

      final boundary = key.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Poster export surface is not ready');
      }

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Could not encode image');
      }

      Uint8List bytes = byteData.buffer.asUint8List();
      if (asJpeg) {
        final decoded = img.decodeImage(bytes);
        if (decoded == null) {
          throw Exception('Could not convert to JPEG');
        }
        bytes = Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
      }

      final ext = asJpeg ? 'jpg' : 'png';
      final slug = _slugify(givenName);
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/birthday-poster-$slug.$ext';
      await File(path).writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(path)],
        text: 'Birthday poster',
      );
    } finally {
      entry.remove();
    }
  }

  static String _slugify(String value) {
    final slug = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return slug.isEmpty ? 'poster' : slug;
  }
}
