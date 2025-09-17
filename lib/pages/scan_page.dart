import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../providers/labour_store.dart';
import 'labour_detail_page.dart';

class ScanPage extends StatefulWidget {
  final String mode; // "attendance" or "payment"
  final String? paymentType; // "heavy" or "low", if mode == "payment"

  const ScanPage({super.key, this.mode = "attendance", this.paymentType});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
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

      if (widget.mode == "attendance") {
        final result = store.markAttendanceById(id);
        if (!mounted) return;
        switch (result) {
          case MarkAttendanceResult.success:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Attendance marked')),
            );
            await _controller.stop();
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => LabourDetailPage(labourId: id),
              ),
            );
            break;
          case MarkAttendanceResult.alreadyMarked:
            await _showInfoDialog(
              'Attendance already done',
              'Attendance for this person is already recorded today.\nPlease scan again tomorrow.',
            );
            break;
          case MarkAttendanceResult.notFound:
            await _showInfoDialog(
              'Labour not found',
              'This QR does not match any labour profile.',
            );
            break;
        }
      } else if (widget.mode == "payment") {
        int amount = widget.paymentType == 'heavy' ? 50 : 30;
        if (widget.paymentType == 'heavy') {
          store.addHeavyPayment(id, amount);
        } else {
          store.addLowPayment(id, amount);
        }
        await _controller.stop();
        if (!mounted) return;
        Navigator.of(context).pop(id); // Return id to PaymentPage
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${labour.name} received Rs $amount.')),
        );
      }
    } finally {
      _handling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.mode == 'attendance' ? 'Scan Attendance' : 'Scan for Payment')),
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