import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/labour_store.dart';
import 'labour_detail_page.dart';

class AddLabourPage extends StatefulWidget {
  const AddLabourPage({super.key});

  @override
  State<AddLabourPage> createState() => _AddLabourPageState();
}

class _AddLabourPageState extends State<AddLabourPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _countryCode = '+977';
  String? _occupation;

  final List<String> occupations = ['Manager', 'Labour', 'Assistant'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Check internet connection before saving
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No internet connection'),
          content: const Text('Please check your connection and try again.'),
          actions: [
            TextButton(
              child: const Text('Ok'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final details =
          'Occupation: ${_occupation ?? ''}\nAddress: ${_addressCtrl.text.trim()}\nPhone: $_countryCode-${_phoneCtrl.text.trim()}';
      final store = context.read<LabourStore>();
      final labour = store.addLabour(
        name: _nameCtrl.text.trim(),
        details: details,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LabourDetailPage(labourId: labour.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Labour')),
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
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Occupation',
                  border: OutlineInputBorder(),
                ),
                value: _occupation,
                items: occupations
                    .map((occ) => DropdownMenuItem(
                          value: occ,
                          child: Text(occ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _occupation = value;
                  });
                },
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Select occupation' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter address' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: TextFormField(
                      initialValue: _countryCode,
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
              const SizedBox(height: 20),
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