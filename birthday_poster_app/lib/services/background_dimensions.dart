import 'dart:async';

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
