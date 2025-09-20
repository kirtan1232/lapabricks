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
    _brickType = brickTypes.contains(parsed['Brick Type']) ? parsed['Brick Type'] : null;
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
              prefixIcon: Icon(Icons.directions_car),
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
        'Brick Type: ${_brickType ?? ''}',
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

    const Color cream = Color(0xFFFFF6E5);
    const Color orangeAccent = Color(0xFFFF9800);
    const Color lightOrange = Color(0xFFFFB74D);

    if (labour == null) {
      return const Scaffold(
        body: Center(child: Text('Labour not found')),
      );
    }

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: orangeAccent,
        title: const Text('Edit Details'),
        elevation: 1,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth < 600
              ? constraints.maxWidth * 0.98
              : constraints.maxWidth < 900
                  ? 500
                  : 650;
          return Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: orangeAccent.withOpacity(0.11),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        'Edit Labour Details',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: orangeAccent,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 22),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          prefixIcon: const Icon(Icons.person, color: orangeAccent),
                          filled: true,
                          fillColor: cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: orangeAccent),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _occupation,
                        items: occupations
                            .map((occ) => DropdownMenuItem(
                                  value: occ,
                                  child: Row(
                                    children: [
                                      Icon(
                                        occ == 'Driver' ? Icons.local_shipping : Icons.build,
                                        color: orangeAccent,
                                        size: 19,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(occ),
                                    ],
                                  ),
                                ))
                            .toList(),
                        decoration: InputDecoration(
                          labelText: 'Occupation',
                          prefixIcon: const Icon(Icons.work, color: orangeAccent),
                          filled: true,
                          fillColor: cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: orangeAccent),
                          ),
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
                        Container(
                          margin: const EdgeInsets.only(top: 7, bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                          decoration: BoxDecoration(
                            color: lightOrange.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.directions_car, color: orangeAccent),
                              const SizedBox(width: 8),
                              Text(
                                'Vehicle Plate: $_vehicleNumber',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _addressCtrl,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          prefixIcon: const Icon(Icons.location_on, color: orangeAccent),
                          filled: true,
                          fillColor: cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: orangeAccent),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter address' : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '+977',
                              style: TextStyle(
                                fontSize: 16,
                                color: orangeAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: const Icon(Icons.phone, color: orangeAccent),
                                filled: true,
                                fillColor: cream,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: orangeAccent),
                                ),
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
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Brick Type',
                          prefixIcon: const Icon(Icons.account_tree, color: orangeAccent),
                          filled: true,
                          fillColor: cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: orangeAccent),
                          ),
                        ),
                        value: _brickType,
                        items: brickTypes
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        color: type == 'Kacho Brick'
                                            ? Colors.brown
                                            : Colors.redAccent,
                                        size: 15,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(type),
                                    ],
                                  ),
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
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _liftCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Lift',
                          prefixIcon: const Icon(Icons.line_weight, color: orangeAccent),
                          filled: true,
                          fillColor: cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: orangeAccent),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter lift';
                          if (!RegExp(r'^[0-9]+$').hasMatch(v)) return 'Only numbers allowed';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _perLiftPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Per Lift Price',
                          prefixIcon: const Icon(Icons.attach_money, color: orangeAccent),
                          filled: true,
                          fillColor: cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: orangeAccent),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter price';
                          if (!RegExp(r'^[0-9]+$').hasMatch(v)) return 'Only numbers allowed';
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orangeAccent,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.save),
                          label: const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          onPressed: _save,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}