import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/poster_data.dart';
import '../services/background_dimensions.dart';
import '../services/poster_exporter.dart';
import '../services/poster_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/editor_form.dart';
import '../widgets/poster_canvas.dart';

class BirthdayPosterScreen extends StatefulWidget {
  const BirthdayPosterScreen({
    super.key,
    this.initialData,
    this.screenTitle = 'Birthday Poster',
  });

  final PosterData? initialData;
  final String screenTitle;

  @override
  State<BirthdayPosterScreen> createState() => _BirthdayPosterScreenState();
}

class _BirthdayPosterScreenState extends State<BirthdayPosterScreen> {
  late final PosterData _data;
  Uint8List? _photoBytes;
  ImageProvider? _background;
  String _status = '';
  bool _exporting = false;
  bool _bgMissing = false;
  double _aspectRatio = PosterLayout.fallbackAspectRatio;
  int _templateNativeWidth = 1280;

  ImageProvider get _backgroundImage =>
      _background ?? const AssetImage('assets/poster_background.jpeg');

  @override
  void initState() {
    super.initState();
    _data = _clonePosterData(widget.initialData ?? PosterData());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBackgroundAsset();
      _resolveBackgroundDimensions(_backgroundImage);
    });
  }

  PosterData _clonePosterData(PosterData source) {
    return PosterData(
      dateText: source.dateText,
      designation: source.designation,
      givenName: source.givenName,
      familyName: source.familyName,
      familyOffsetX: source.familyOffsetX,
      familyOffsetY: source.familyOffsetY,
      familyFontSize: source.familyFontSize,
      photoPosX: source.photoPosX,
      photoPosY: source.photoPosY,
      photoZoom: source.photoZoom,
      rolesLeft: source.rolesLeft,
      rolesTop: source.rolesTop,
      rolesWidth: source.rolesWidth,
      rolesHeight: source.rolesHeight,
      rolesPadBottom: source.rolesPadBottom,
      rolesAlign: source.rolesAlign,
      rolesTextScale: source.rolesTextScale,
      positions: source.positions
          .map((position) => position.copyWith())
          .toList(),
    );
  }

  void _refresh() => setState(() {});

  PosterCanvas _buildPoster({required bool showShadow}) {
    return PosterCanvas(
      data: _data,
      photoBytes: _photoBytes,
      customBackground: _background,
      aspectRatio: _aspectRatio,
      showShadow: showShadow,
    );
  }

  Future<void> _export({required bool jpeg}) async {
    setState(() {
      _exporting = true;
      _status = 'Preparing export…';
    });

    try {
      await PosterFonts.ensureLoaded();
      await PosterExporter.exportAndShare(
        context: context,
        templateWidth: _templateNativeWidth.toDouble(),
        givenName: _data.givenName,
        asJpeg: jpeg,
        poster: _buildPoster(showShadow: false),
      );
      if (!mounted) return;
      setState(() => _status = 'Shared ${jpeg ? 'JPEG' : 'PNG'} poster.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _applyBackgroundDimensions(({int width, int height}) dims) {
    setState(() {
      _aspectRatio = dims.width / dims.height;
      _templateNativeWidth = dims.width;
    });
  }

  Future<void> _resolveBackgroundDimensions(ImageProvider provider) async {
    if (!mounted) return;
    final dims = await resolveImageDimensions(provider, context);
    if (!mounted || dims == null) return;
    _applyBackgroundDimensions(dims);
  }

  Future<void> _pickBackground() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final dims = await resolveBytesDimensions(bytes);
    if (!mounted) return;
    setState(() {
      _background = MemoryImage(bytes);
      _bgMissing = false;
      _status = 'Custom background loaded.';
      if (dims != null) {
        _aspectRatio = dims.width / dims.height;
        _templateNativeWidth = dims.width;
      }
    });
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
        title: Text(widget.screenTitle),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxPreviewWidth = constraints.maxWidth - padding.horizontal;
          final maxPreviewHeight = constraints.maxHeight - padding.vertical;
          final size = fitPosterSize(
            BoxConstraints(
              maxWidth: maxPreviewWidth.clamp(0, 540),
              maxHeight: maxPreviewHeight,
            ),
            _aspectRatio,
          );

          return Center(
            child: Padding(
              padding: padding,
              child: GestureDetector(
                onTap: _bgMissing ? _pickBackground : null,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: _buildPoster(showShadow: true),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
