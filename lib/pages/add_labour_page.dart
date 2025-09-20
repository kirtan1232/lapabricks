import 'package:flutter/material.dart';
import 'package:lapabricks/pages/labour_detail_page.dart';
import 'package:lapabricks/providers/labour_store.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
  String? _brickType;

  final List<String> occupations = ['Labour', 'Driver'];
  final List<String> brickTypes = ['Kacho Brick', 'Pako Brick'];

  // Colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color accentTeal = Color(0xFF06B6D4);
  static const Color backgroundGray = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);

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

    if (_occupation == 'Driver' &&
        (_vehicleNumber == null || !_vehicleNumber!.contains(RegExp(r'^\d{4}$')))) {
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
        'Brick Type: ${_brickType ?? ''}',
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
                'Lapa Bricks',
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
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                margin: const EdgeInsets.symmetric(horizontal: 8),
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
                              'New Labour Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: primaryBlue, // Now blue
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
                        decoration: _inputDecoration(
                          label: 'Occupation',
                          icon: Icons.work_rounded,
                        ),
                        value: _occupation,
                        items: occupations
                            .map((occ) => DropdownMenuItem(
                                  value: occ,
                                  child: Row(
                                    children: [
                                      Icon(
                                        occ == 'Driver'
                                            ? Icons.local_shipping
                                            : Icons.build,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(occ, style: TextStyle(color: Colors.black)),
                                    ],
                                  ),
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
                            (value == null || value.isEmpty)
                                ? 'Select occupation'
                                : null,
                      ),
                      if (_occupation == 'Driver' && _vehicleNumber != null)
                        Container(
                          margin: const EdgeInsets.only(top: 7, bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 7),
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, color: Colors.black),
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              _countryCode,
                              style: const TextStyle(
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
                                if (phoneNum.isEmpty)
                                  return 'Enter phone number';
                                if (!RegExp(r'^[0-9]{10}$')
                                    .hasMatch(phoneNum)) {
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
                            (value == null || value.isEmpty)
                                ? 'Select brick type'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      _buildInput(
                        controller: _liftCtrl,
                        label: 'Lift',
                        icon: Icons.line_weight_rounded,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Enter lift';
                          if (!RegExp(r'^[0-9]+$').hasMatch(v))
                            return 'Only numbers allowed';
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
                          if (v == null || v.trim().isEmpty)
                            return 'Enter price';
                          if (!RegExp(r'^[0-9]+$').hasMatch(v))
                            return 'Only numbers allowed';
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
                            'Save Labour',
                            style:
                                TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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