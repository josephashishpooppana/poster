import 'package:flutter/material.dart';

import '../models/anniversary_event.dart';
import '../models/priest_record.dart';
import '../services/priest_csv_parser.dart';
import '../services/priest_repository.dart';

class EditPriestDialog extends StatefulWidget {
  const EditPriestDialog({
    super.key,
    required this.event,
  });

  final AnniversaryEvent event;

  static Future<bool?> show(BuildContext context, AnniversaryEvent event) {
    return showDialog<bool>(
      context: context,
      builder: (_) => EditPriestDialog(event: event),
    );
  }

  @override
  State<EditPriestDialog> createState() => _EditPriestDialogState();
}

class _EditPriestDialogState extends State<EditPriestDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _designationController;
  late final TextEditingController _servingAtController;
  late final TextEditingController _addressController;
  late DateTime? _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final priest = widget.event.priest;
    _nameController = TextEditingController(text: priest.fullName);
    _designationController = TextEditingController(text: priest.designation);
    _servingAtController = TextEditingController(text: priest.servingAt);
    _addressController = TextEditingController(text: priest.address);
    _date = widget.event.sourceDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _designationController.dispose();
    _servingAtController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = _date ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date.')),
      );
      return;
    }

    setState(() => _saving = true);

    final updated = PriestRecord(
      fullName: _nameController.text.trim(),
      designation: _designationController.text.trim(),
      servingAt: _servingAtController.text.trim(),
      address: _addressController.text.trim(),
      birthDate: widget.event.type == AnniversaryType.birthday
          ? _date
          : widget.event.priest.birthDate,
      ordinationDate: widget.event.type == AnniversaryType.ordination
          ? _date
          : widget.event.priest.ordinationDate,
    );

    final result = await PriestRepository.instance.updatePriest(
      originalKey: widget.event.priest.key,
      updated: updated,
      eventType: widget.event.type,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.syncedToSheet || result.message.contains('Saved locally')) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = widget.event.type == AnniversaryType.birthday
        ? 'Date of Birth'
        : 'Ordination Date';
    final dateText = _date != null
        ? PriestCsvParser.formatSheetDate(_date!)
        : 'Select date';

    return AlertDialog(
      title: Text('Edit ${widget.event.title}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _designationController,
                  decoration: const InputDecoration(labelText: 'Designation'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _servingAtController,
                  decoration: const InputDecoration(labelText: 'Serving At'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(dateLabel),
                  subtitle: Text(dateText),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: _saving ? null : _pickDate,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
