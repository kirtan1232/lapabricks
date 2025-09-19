import 'package:flutter/material.dart';
import 'package:lapabricks/providers/labour_store.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PaymentScanPage extends StatefulWidget {
  const PaymentScanPage({super.key});

  @override
  State<PaymentScanPage> createState() => _PaymentScanPageState();
}

class _PaymentScanPageState extends State<PaymentScanPage> {
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

  Future<void> _handleBarcode(String? value) async {
    if (_handling) return;
    _handling = true;
    try {
      if (value == null) return;
      if (!value.startsWith('labour:')) return;
      final id = value.substring('labour:'.length);
      await _controller.stop();
      if (!mounted) return;
      Navigator.of(context).pop(id);
    } finally {
      _handling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan for Payment')),
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

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  void _scan(BuildContext context) async {
    final labourId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const PaymentScanPage()),
    );
    if (labourId == null) return;
    final store = context.read<LabourStore>();
    store.addLift(labourId); // Only runs ONCE per scan!

    final labour = store.byId(labourId);
    if (labour == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
      return;
    }
    final now = DateTime.now();
    final todayStr = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final todayRecord = labour.dailyRecords[todayStr] ?? {};
    final todayTotal = todayRecord['earnings'] ?? 0;
    final todayLifts = todayRecord['lifts'] ?? 0;
    final total = labour.totalEarnings;
    final monthly = labour.monthlyEarnings(DateTime.now());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${labour.name} received Rs ${labour.perLiftPrice}. Today: Rs $todayTotal (Lifts: $todayLifts), Monthly: Rs $monthly, Total: Rs $total'
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Center(
        child: FilledButton(
          onPressed: () => _scan(context),
          child: const Text('Scan'),
        ),
      ),
    );
  }
}