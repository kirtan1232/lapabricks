import 'package:flutter/material.dart';
import 'package:lapabricks/pages/labour_detail_page.dart';
import 'package:lapabricks/providers/labour_store.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';


class AttendanceScanPage extends StatefulWidget {
  const AttendanceScanPage({super.key});

  @override
  State<AttendanceScanPage> createState() => _AttendanceScanPageState();
}

class _AttendanceScanPageState extends State<AttendanceScanPage> {
  late final MobileScannerController _controller;
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.qrCode],
      facing: CameraFacing.back,
      returnImage: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showInfoDialog(String title, String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBarcode(String? value) async {
    if (_handling) return;
    _handling = true;

    try {
      if (value == null) return;
      if (!value.startsWith('labour:')) {
        await _showInfoDialog('Invalid QR', 'This QR code is not recognized.');
        return;
      }

      final id = value.substring('labour:'.length);
      final store = context.read<LabourStore>();
      final labour = store.byId(id);

      if (labour == null) {
        await _showInfoDialog('Labour not found', 'This QR does not match any labour profile.');
        return;
      }

      // Mark attendance and add lift/payment regardless of attendance status
      store.markAttendanceById(id);
      store.addLift(id);

      await _controller.stop();
      if (!mounted) return;

      // Show green snackbar with "Record Updated"
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Record Updated'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LabourDetailPage(labourId: id),
        ),
      );
    } finally {
      _handling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Attendance')),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          if (barcodes.isEmpty) return;
          final raw = barcodes.first.rawValue;
          _handleBarcode(raw);
        },
        errorBuilder: (context, error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Camera error: $error'),
            ),
          );
        },
        placeholderBuilder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}