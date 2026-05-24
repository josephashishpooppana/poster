import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/poster_data.dart';
import '../services/poster_exporter.dart';
import '../theme/app_theme.dart';
import '../widgets/editor_form.dart';
import '../widgets/poster_canvas.dart';

class BirthdayPosterScreen extends StatefulWidget {
  const BirthdayPosterScreen({super.key});

  @override
  State<BirthdayPosterScreen> createState() => _BirthdayPosterScreenState();
}

class _BirthdayPosterScreenState extends State<BirthdayPosterScreen> {
  final _posterKey = GlobalKey();
  final _data = PosterData();
  Uint8List? _photoBytes;
  ImageProvider? _background;
  String _status = '';
  bool _exporting = false;
  bool _bgMissing = false;

  void _refresh() => setState(() {});

  Future<void> _export({required bool jpeg}) async {
    setState(() {
      _exporting = true;
      _status = 'Preparing export…';
    });

    try {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await PosterExporter.exportAndShare(
        repaintKey: _posterKey,
        givenName: _data.givenName,
        asJpeg: jpeg,
      );
      setState(() => _status = 'Shared ${jpeg ? 'JPEG' : 'PNG'} poster.');
    } catch (e) {
      setState(() => _status = 'Export failed: $e');
    } finally {
      setState(() => _exporting = false);
    }
  }

  Future<void> _pickBackground() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _background = MemoryImage(bytes);
      _bgMissing = false;
      _status = 'Custom background loaded.';
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkBackgroundAsset());
  }

  Future<void> _checkBackgroundAsset() async {
    try {
      await DefaultAssetBundle.of(context)
          .load('assets/poster_background.jpeg');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bgMissing = true;
        _status =
            'Add assets/poster_background.jpeg or tap the poster to pick a template.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Birthday Poster'),
        actions: [
          if (_bgMissing)
            TextButton.icon(
              onPressed: _pickBackground,
              icon: const Icon(Icons.image_outlined, color: Colors.white),
              label: const Text('Template', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: wide ? _wideLayout() : _narrowLayout(),
    );
  }

  Widget _wideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 380,
          child: ColoredBox(
            color: Colors.white,
            child: EditorForm(
              data: _data,
              onChanged: _refresh,
              photoBytes: _photoBytes,
              onPhotoChanged: (bytes) {
                setState(() {
                  _photoBytes = bytes;
                  if (bytes != null) _status = 'Photo added to poster.';
                });
              },
              onExportPng: () => _export(jpeg: false),
              onExportJpeg: () => _export(jpeg: true),
              statusMessage: _status,
              isExporting: _exporting,
            ),
          ),
        ),
        const VerticalDivider(width: 1, color: AppColors.panelBorder),
        Expanded(child: _previewArea()),
      ],
    );
  }

  Widget _narrowLayout() {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: _previewArea(padding: const EdgeInsets.all(12)),
        ),
        const Divider(height: 1, color: AppColors.panelBorder),
        Expanded(
          flex: 6,
          child: ColoredBox(
            color: Colors.white,
            child: EditorForm(
              data: _data,
              onChanged: _refresh,
              photoBytes: _photoBytes,
              onPhotoChanged: (bytes) {
                setState(() {
                  _photoBytes = bytes;
                  if (bytes != null) _status = 'Photo added to poster.';
                });
              },
              onExportPng: () => _export(jpeg: false),
              onExportJpeg: () => _export(jpeg: true),
              statusMessage: _status,
              isExporting: _exporting,
            ),
          ),
        ),
      ],
    );
  }

  Widget _previewArea({EdgeInsets padding = const EdgeInsets.all(20)}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8EFE9), Color(0xFFDCE8E4)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: padding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: GestureDetector(
              onTap: _bgMissing ? _pickBackground : null,
              child: RepaintBoundary(
                key: _posterKey,
                child: PosterCanvas(
                  data: _data,
                  photoBytes: _photoBytes,
                  customBackground: _background,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
