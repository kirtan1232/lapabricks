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
  String _occupation = 'Labour';
  String? _vehicleNumber;
  String? _brickType;

  static const List<String> occupations = ['Labour', 'Driver'];
  static const List<String> brickTypes = ['Kacho Brick', 'Pako Brick'];

  // Colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color accentTeal = Color(0xFF06B6D4);
  static const Color backgroundGray = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);

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

    if (labour == null) {
      return const Scaffold(
        body: Center(child: Text('Labour not found')),
      );
    }

    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        backgroundColor: cardWhite,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        titleSpacing: 0,
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LAPA BRICKS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: primaryBlue,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
              Container(
                height: 3,
                width: 60,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue, accentTeal],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth < 600
              ? constraints.maxWidth * 0.98
              : constraints.maxWidth < 1000
                  ? 540
                  : 700;
          return Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cardWhite,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        child: Column(
                          children: [
                            Text(
                              'Edit Labour Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: primaryBlue,
                              ),
                            ),
                            Container(
                              height: 3,
                              width: 52,
                              margin: const EdgeInsets.only(top: 5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryBlue, accentTeal],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 7),
                      _buildInput(
                        controller: _nameCtrl,
                        label: 'Name',
                        icon: Icons.person_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _occupation,
                        items: occupations
                            .map((occ) => DropdownMenuItem(
                                  value: occ,
                                  child: Row(
                                    children: [
                                      Icon(
                                        occ == 'Driver' ? Icons.local_shipping : Icons.build,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(occ, style: TextStyle(color: Colors.black)),
                                    ],
                                  ),
                                ))
                            .toList(),
                        decoration: _inputDecoration(
                          label: 'Occupation',
                          icon: Icons.work_rounded,
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
                            color: accentTeal.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.directions_car),
                              const SizedBox(width: 8),
                              Text(
                                'Vehicle Plate: $_vehicleNumber',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      _buildInput(
                        controller: _addressCtrl,
                        label: 'Address',
                        icon: Icons.location_on_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter address'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: const Text(
                              '+977',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInput(
                              controller: _phoneCtrl,
                              label: 'Phone Number',
                              icon: Icons.phone_rounded,
                              validator: (v) {
                                final phoneNum = v?.trim() ?? '';
                                if (phoneNum.isEmpty) return 'Enter phone number';
                                if (!RegExp(r'^[0-9]{10}$').hasMatch(phoneNum)) {
                                  return 'Phone number must be exactly 10 digits';
                                }
                                return null;
                              },
                              type: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration(
                          label: 'Brick Type',
                          icon: Icons.account_tree_rounded,
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
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(type, style: TextStyle(color: Colors.black)),
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
                      const SizedBox(height: 12),
                      _buildInput(
                        controller: _liftCtrl,
                        label: 'Lift',
                        icon: Icons.line_weight_rounded,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter lift';
                          if (!RegExp(r'^[0-9]+$').hasMatch(v)) return 'Only numbers allowed';
                          return null;
                        },
                        type: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _buildInput(
                        controller: _perLiftPriceCtrl,
                        label: 'Per Lift Price',
                        icon: Icons.attach_money_rounded,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter price';
                          if (!RegExp(r'^[0-9]+$').hasMatch(v)) return 'Only numbers allowed';
                          return null;
                        },
                        type: TextInputType.number,
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.save_rounded),
                          label: const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: backgroundGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.black, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 15),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(
        fontSize: 15,
        color: Colors.black,
        fontWeight: FontWeight.w500,
      ),
      decoration: _inputDecoration(label: label, icon: icon),
      validator: validator,
    );
  }
}