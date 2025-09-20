import 'dart:async';
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

  Future<void> _showCountdownDialog(Duration duration) async {
    int secondsLeft = duration.inSeconds;
    Timer? timer;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (timer == null) {
              timer = Timer.periodic(const Duration(seconds: 1), (t) {
                if (secondsLeft > 0) {
                  setState(() => secondsLeft--);
                } else {
                  timer?.cancel();
                }
              });
            }
            String formatDuration(int s) {
              final m = (s ~/ 60).toString().padLeft(2, '0');
              final sec = (s % 60).toString().padLeft(2, '0');
              return '$m:$sec';
            }
            return AlertDialog(
              title: const Text('Scan Cooldown'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Please wait before you can scan again.'),
                  const SizedBox(height: 18),
                  Text(
                    formatDuration(secondsLeft),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ],
              ),
              actions: [
                if (secondsLeft == 0)
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () {
                      timer?.cancel();
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            );
          },
        );
      },
    );

    timer?.cancel();
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

      // Get occupation from details
      String occupation = 'Labour';
      for (final line in (labour.details ?? '').split('\n')) {
        if (line.startsWith('Occupation:')) {
          occupation = line.split(':').last.trim();
        }
      }
      Duration timeout = occupation == 'Driver' ? const Duration(minutes: 30) : const Duration(minutes: 5);

      final now = DateTime.now();
      final lastScan = store.scanCooldowns[id];
      if (lastScan != null) {
        final elapsed = now.difference(lastScan);
        if (elapsed < timeout) {
          await _showCountdownDialog(timeout - elapsed);
          return; // Don't add attendance or money if in cooldown
        }
      }

      // Mark attendance and add lift/payment
      store.markAttendanceById(id);
      store.addLift(id);

      await store.updateScanCooldown(id, now);

      await _controller.stop();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Record Updated ($occupation)'),
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