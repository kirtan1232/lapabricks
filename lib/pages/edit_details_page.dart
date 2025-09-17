import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/labour.dart';
import '../providers/labour_store.dart';

class EditDetailsPage extends StatefulWidget {
  final String labourId;
  const EditDetailsPage({super.key, required this.labourId});

  @override
  State<EditDetailsPage> createState() => _EditDetailsPageState();
}

class _EditDetailsPageState extends State<EditDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  String _occupation = 'Labour'; // default

  static const List<String> occupations = ['Labour', 'Manager', 'Assistant'];

  @override
  void initState() {
    super.initState();
    final store = context.read<LabourStore>();
    final labour = store.byId(widget.labourId);

    Map<String, String> parseDetails(String details) {
      final lines = details.split('\n');
      final data = <String, String>{};
      for (final line in lines) {
        final idx = line.indexOf(':');
        if (idx > -1) {
          final key = line.substring(0, idx).trim();
          final value = line.substring(idx + 1).trim();
          data[key] = value;
        }
      }
      return data;
    }

    final parsed = labour != null ? parseDetails(labour.details) : {};

    _nameCtrl = TextEditingController(text: labour?.name ?? '');
    _occupation = occupations.contains(parsed['Occupation']) ? parsed['Occupation']! : 'Labour';
    _addressCtrl = TextEditingController(text: parsed['Address'] ?? '');

    String phone = parsed['Phone'] ?? '';
    if (phone.startsWith('+977-')) {
      phone = phone.replaceFirst('+977-', '');
    } else if (phone.startsWith('+977')) {
      phone = phone.replaceFirst('+977', '');
    }
    _phoneCtrl = TextEditingController(text: phone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final store = context.read<LabourStore>();
      final details =
          'Occupation: $_occupation\nAddress: ${_addressCtrl.text.trim()}\nPhone: +977-${_phoneCtrl.text.trim()}';
      store.editLabour(
        id: widget.labourId,
        name: _nameCtrl.text.trim(),
        details: details,
      );
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Details updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LabourStore>();
    final labour = store.byId(widget.labourId);

    if (labour == null) {
      return const Scaffold(
        body: Center(child: Text('Labour not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _occupation,
                items: occupations
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                decoration: const InputDecoration(
                  labelText: 'Occupation',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  setState(() {
                    _occupation = v ?? 'Labour';
                  });
                },
                validator: (v) => v == null || v.isEmpty ? 'Select occupation' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter address' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: '+977',
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final phoneNum = v?.trim() ?? '';
                        if (phoneNum.isEmpty) return 'Enter phone number';
                        if (!RegExp(r'^[0-9]{10}$').hasMatch(phoneNum)) {
                          return 'Phone number must be exactly 10 digits';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}