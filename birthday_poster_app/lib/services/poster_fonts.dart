import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ensures poster fonts are downloaded before first render/export.
class PosterFonts {
  static Future<void>? _pending;

  static Future<void> ensureLoaded() {
    _pending ??= GoogleFonts.pendingFonts([
      GoogleFonts.barlowCondensed(fontWeight: FontWeight.w800),
      GoogleFonts.montserrat(fontWeight: FontWeight.w500),
      GoogleFonts.montserrat(fontWeight: FontWeight.w800),
      GoogleFonts.montserrat(fontWeight: FontWeight.w900),
      GoogleFonts.greatVibes(),
    ]);
    return _pending!;
  }
}
