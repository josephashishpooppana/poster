import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Resolves the pixel dimensions of an [ImageProvider].
Future<({int width, int height})?> resolveImageDimensions(
  ImageProvider provider,
  BuildContext context,
) async {
  final completer = Completer<({int width, int height})?>();
  final stream = provider.resolve(createLocalImageConfiguration(context));
  late ImageStreamListener listener;
  listener = ImageStreamListener(
    (ImageInfo info, bool _) {
      stream.removeListener(listener);
      completer.complete((
        width: info.image.width,
        height: info.image.height,
      ));
    },
    onError: (_, __) {
      stream.removeListener(listener);
      completer.complete(null);
    },
  );
  stream.addListener(listener);
  return completer.future;
}

/// Resolves dimensions from raw image bytes (e.g. picked gallery file).
Future<({int width, int height})?> resolveBytesDimensions(
  Uint8List bytes,
) async {
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final size = (
      width: frame.image.width,
      height: frame.image.height,
    );
    frame.image.dispose();
    return size;
  } catch (_) {
    return null;
  }
}

/// Computes the largest width/height that fits [constraints] at [aspectRatio]
/// (width ÷ height, matching CSS/HTML `aspect-ratio: W / H`).
({double width, double height}) fitPosterSize(
  BoxConstraints constraints,
  double aspectRatio,
) {
  final maxW = constraints.hasBoundedWidth && constraints.maxWidth.isFinite
      ? constraints.maxWidth
      : 540.0;
  final maxH = constraints.hasBoundedHeight && constraints.maxHeight.isFinite
      ? constraints.maxHeight
      : maxW / aspectRatio;

  var width = maxW;
  var height = width / aspectRatio;

  if (height > maxH) {
    height = maxH;
    width = height * aspectRatio;
  }

  return (width: width, height: height);
}
