import 'package:flutter/material.dart';
import 'package:lapabricks/providers/labour_store.dart';
import 'package:provider/provider.dart';


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
  late TextEditingController _liftCtrl;
  late TextEditingController _perLiftPriceCtrl;
  String _occupation = 'Labour'; // default
  String? _vehicleNumber;
  String? _brickType; // <-- Added

  static const List<String> occupations = ['Labour', 'Driver'];
  static const List<String> brickTypes = ['Kacho Brick', 'Pako Brick'];

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

    _vehicleNumber = parsed['Vehicle Plate'];
    _liftCtrl = TextEditingController(text: parsed['Lift'] ?? '');
    _perLiftPriceCtrl = TextEditingController(text: labour?.perLiftPrice.toString() ?? '');
    _brickType = brickTypes.contains(parsed['Brick Type']) ? parsed['Brick Type'] : null; // <-- Added
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _liftCtrl.dispose();
    _perLiftPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _askVehicleNumber() async {
    String? enteredNumber;
    await showDialog(
      context: context,
      builder: (context) {
        final vehicleCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Enter Vehicle Plate Number'),
          content: TextFormField(
            controller: vehicleCtrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(
              labelText: '4-digit plate number',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Enter number';
              if (!RegExp(r'^\d{4}$').hasMatch(value)) {
                return 'Enter exactly 4 digits';
              }
              return null;
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                if (RegExp(r'^\d{4}$').hasMatch(vehicleCtrl.text)) {
                  enteredNumber = vehicleCtrl.text;
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
    setState(() {
      _vehicleNumber = enteredNumber;
    });
  }

  void _save() {
    if (_occupation == 'Driver' && (_vehicleNumber == null || !_vehicleNumber!.contains(RegExp(r'^\d{4}$')))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid 4-digit vehicle plate number for Driver'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      final store = context.read<LabourStore>();
      final details = [
        'Occupation: $_occupation',
        'Address: ${_addressCtrl.text.trim()}',
        'Phone: +977-${_phoneCtrl.text.trim()}',
        if (_occupation == 'Driver') 'Vehicle Plate: $_vehicleNumber',
        'Lift: ${_liftCtrl.text.trim()}',
        'Brick Type: ${_brickType ?? ''}', // <-- Added
      ].join('\n');

      final perLiftPrice = int.tryParse(_perLiftPriceCtrl.text.trim()) ?? 0;

      store.editLabour(
        id: widget.labourId,
        name: _nameCtrl.text.trim(),
        details: details,
        perLiftPrice: perLiftPrice,
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
                onChanged: (v) async {
                  setState(() {
                    _occupation = v ?? 'Labour';
                  });
                  if (v == 'Driver') {
                    await _askVehicleNumber();
                  } else {
                    setState(() {
                      _vehicleNumber = null;
                    });
                  }
                },
                validator: (v) => v == null || v.isEmpty ? 'Select occupation' : null,
              ),
              if (_occupation == 'Driver' && _vehicleNumber != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Vehicle Plate: $_vehicleNumber',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
              const SizedBox(height: 12),
              // Brick Type dropdown below phone number
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Brick Type',
                  border: OutlineInputBorder(),
                ),
                value: _brickType,
                items: brickTypes
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _brickType = value;
                  });
                },
                validator: (value) =>
                (value == null || value.isEmpty) ? 'Select brick type' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _liftCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Lift',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter lift';
                  if (!RegExp(r'^[0-9]+$').hasMatch(v)) return 'Only numbers allowed';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _perLiftPriceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Per Lift Price',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter price';
                  if (!RegExp(r'^[0-9]+$').hasMatch(v)) return 'Only numbers allowed';
                  return null;
                },
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