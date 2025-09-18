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
  final _liftCtrl = TextEditingController();
  final _perLiftPriceCtrl = TextEditingController();
  String _countryCode = '+977';
  String? _occupation;
  String? _vehicleNumber;

  final List<String> occupations = ['Labour', 'Driver'];

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

  Future<void> _save() async {
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

    if (_occupation == 'Driver' && (_vehicleNumber == null || !_vehicleNumber!.contains(RegExp(r'^\d{4}$')))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter valid 4-digit vehicle plate number for Driver'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final details = [
        'Occupation: ${_occupation ?? ''}',
        'Address: ${_addressCtrl.text.trim()}',
        'Phone: $_countryCode-${_phoneCtrl.text.trim()}',
        if (_occupation == 'Driver') 'Vehicle Plate: $_vehicleNumber',
        'Lift: ${_liftCtrl.text.trim()}',
      ].join('\n');

      final store = context.read<LabourStore>();
      final perLiftPrice = int.tryParse(_perLiftPriceCtrl.text.trim()) ?? 0;

      final labour = store.addLabour(
        name: _nameCtrl.text.trim(),
        details: details,
        perLiftPrice: perLiftPrice,
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
                onChanged: (value) async {
                  setState(() {
                    _occupation = value;
                  });
                  if (value == 'Driver') {
                    await _askVehicleNumber();
                  } else {
                    setState(() {
                      _vehicleNumber = null;
                    });
                  }
                },
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Select occupation' : null,
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