import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/poster_data.dart';
import '../theme/app_theme.dart';

class EditorForm extends StatelessWidget {
  const EditorForm({
    super.key,
    required this.data,
    required this.onChanged,
    required this.photoBytes,
    required this.onPhotoChanged,
    required this.onExportPng,
    required this.onExportJpeg,
    required this.statusMessage,
    required this.isExporting,
  });

  final PosterData data;
  final VoidCallback onChanged;
  final Uint8List? photoBytes;
  final ValueChanged<Uint8List?> onPhotoChanged;
  final VoidCallback onExportPng;
  final VoidCallback onExportJpeg;
  final String statusMessage;
  final bool isExporting;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Edit content'),
        _textField(
          label: 'Date (e.g. APR 24)',
          value: data.dateText,
          onChanged: (v) {
            data.dateText = v;
            onChanged();
          },
        ),
        _textField(
          label: 'Designation (e.g. Rev. Fr.)',
          value: data.designation,
          onChanged: (v) {
            data.designation = v;
            onChanged();
          },
        ),
        _textField(
          label: 'Given name (displayed in capitals)',
          value: data.givenName,
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) {
            data.givenName = v.toUpperCase();
            onChanged();
          },
        ),
        _textField(
          label: 'Family / surname (script)',
          value: data.familyName,
          onChanged: (v) {
            data.familyName = v;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        _subsection('Family name position & size'),
        _numberPair(
          leftLabel: 'Horizontal (% from left)',
          leftValue: data.familyOffsetX,
          rightLabel: 'Vertical (em down)',
          rightValue: data.familyOffsetY,
          rightDecimals: 2,
          onLeft: (v) {
            data.familyOffsetX = v;
            onChanged();
          },
          onRight: (v) {
            data.familyOffsetY = v;
            onChanged();
          },
        ),
        _numberField(
          label: 'Size (em)',
          value: data.familyFontSize,
          min: 2,
          max: 8,
          step: 0.1,
          onChanged: (v) {
            data.familyFontSize = v;
            onChanged();
          },
        ),
        const SizedBox(height: 16),
        _photoSection(context),
        if (photoBytes != null) ...[
          const SizedBox(height: 16),
          _subsection('Photo crop & position'),
          _numberPair(
            leftLabel: 'Horizontal (%)',
            leftValue: data.photoPosX,
            rightLabel: 'Vertical (%)',
            rightValue: data.photoPosY,
            onLeft: (v) {
              data.photoPosX = v;
              onChanged();
            },
            onRight: (v) {
              data.photoPosY = v;
              onChanged();
            },
          ),
          _numberField(
            label: 'Zoom (%)',
            value: data.photoZoom,
            min: 50,
            max: 220,
            step: 5,
            onChanged: (v) {
              data.photoZoom = v;
              onChanged();
            },
          ),
        ],
        const SizedBox(height: 20),
        _sectionTitle('Positions & locations'),
        ...List.generate(data.positions.length, (index) {
          final pos = data.positions[index];
          return _positionCard(
            index: index,
            position: pos,
            canRemove: data.positions.length > 1,
            onRemove: () {
              data.positions.removeAt(index);
              onChanged();
            },
            onChanged: onChanged,
          );
        }),
        OutlinedButton.icon(
          onPressed: () {
            data.positions.add(ChurchPosition());
            onChanged();
          },
          icon: const Icon(Icons.add),
          label: const Text('Add position'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.teal,
            side: const BorderSide(color: AppColors.teal),
          ),
        ),
        const SizedBox(height: 20),
        _subsection('Positions box on poster'),
        _numberPair(
          leftLabel: 'Left (%)',
          leftValue: data.rolesLeft,
          rightLabel: 'Top (%)',
          rightValue: data.rolesTop,
          onLeft: (v) {
            data.rolesLeft = v;
            onChanged();
          },
          onRight: (v) {
            data.rolesTop = v;
            onChanged();
          },
        ),
        const SizedBox(height: 10),
        _numberPair(
          leftLabel: 'Width (%)',
          leftValue: data.rolesWidth,
          rightLabel: 'Height (%)',
          rightValue: data.rolesHeight,
          onLeft: (v) {
            data.rolesWidth = v;
            onChanged();
          },
          onRight: (v) {
            data.rolesHeight = v;
            onChanged();
          },
        ),
        const SizedBox(height: 10),
        _numberField(
          label: 'Padding bottom (em)',
          value: data.rolesPadBottom,
          min: 0,
          max: 2,
          step: 0.05,
          decimals: 2,
          onChanged: (v) {
            data.rolesPadBottom = v;
            onChanged();
          },
        ),
        DropdownButtonFormField<RolesVerticalAlign>(
          value: data.rolesAlign,
          decoration: const InputDecoration(labelText: 'Text vertical align'),
          items: const [
            DropdownMenuItem(value: RolesVerticalAlign.bottom, child: Text('Bottom')),
            DropdownMenuItem(value: RolesVerticalAlign.top, child: Text('Top')),
            DropdownMenuItem(value: RolesVerticalAlign.center, child: Text('Center')),
          ],
          onChanged: (v) {
            if (v != null) {
              data.rolesAlign = v;
              onChanged();
            }
          },
        ),
        const SizedBox(height: 10),
        _numberField(
          label: 'Text size scale',
          value: data.rolesTextScale,
          min: 0.5,
          max: 1.5,
          step: 0.05,
          decimals: 2,
          onChanged: (v) {
            data.rolesTextScale = v;
            onChanged();
          },
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: isExporting ? null : onExportPng,
                child: const Text('Export PNG'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: isExporting ? null : onExportJpeg,
                child: const Text('Export JPEG'),
              ),
            ),
          ],
        ),
        if (statusMessage.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            statusMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
          ),
        ],
      ],
    );
  }

  Widget _photoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Portrait photo',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
            if (photoBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  photoBytes!,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: () => _pickPhoto(context),
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(photoBytes == null ? 'Choose photo' : 'Change photo'),
            ),
            if (photoBytes != null)
              TextButton(
                onPressed: () => onPhotoChanged(null),
                child: const Text('Remove photo'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 92,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    onPhotoChanged(bytes);
  }

  Widget _positionCard({
    required int index,
    required ChurchPosition position,
    required bool canRemove,
    required VoidCallback onRemove,
    required VoidCallback onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFFF8FAF9),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (canRemove)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, color: Colors.redAccent),
                  tooltip: 'Remove',
                ),
              ),
            _textField(
              label: 'Position',
              value: position.title,
              onChanged: (v) {
                position.title = v;
                onChanged();
              },
            ),
            _textField(
              label: 'Location',
              value: position.location,
              onChanged: (v) {
                position.location = v;
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.teal,
        ),
      ),
    );
  }

  Widget _subsection(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }

  Widget _textField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        textCapitalization: textCapitalization,
        onChanged: onChanged,
      ),
    );
  }

  Widget _numberField({
    required String label,
    required double value,
    required double min,
    required double max,
    required double step,
    int decimals = 1,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value.toStringAsFixed(decimals),
        decoration: InputDecoration(labelText: label),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (raw) {
          final parsed = double.tryParse(raw);
          if (parsed != null) onChanged(parsed.clamp(min, max));
        },
      ),
    );
  }

  Widget _numberPair({
    required String leftLabel,
    required double leftValue,
    required String rightLabel,
    required double rightValue,
    required ValueChanged<double> onLeft,
    required ValueChanged<double> onRight,
    int rightDecimals = 1,
  }) {
    return Row(
      children: [
        Expanded(
          child: _numberField(
            label: leftLabel,
            value: leftValue,
            min: 0,
            max: 100,
            step: 1,
            onChanged: onLeft,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _numberField(
            label: rightLabel,
            value: rightValue,
            min: -10,
            max: 10,
            step: 0.05,
            decimals: rightDecimals,
            onChanged: onRight,
          ),
        ),
      ],
    );
  }
}
