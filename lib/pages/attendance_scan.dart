import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lapabricks/pages/labour_detail_page.dart';
import 'package:lapabricks/providers/labour_store.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceScanPage extends StatefulWidget {
  const AttendanceScanPage({super.key});

  @override
  State<AttendanceScanPage> createState() => _AttendanceScanPageState();
}

class _AttendanceScanPageState extends State<AttendanceScanPage> {
  late final MobileScannerController _controller;
  bool _handling = false;

  // Modern color scheme matching other pages
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color lightBlue = Color(0xFF3B82F6);
  static const Color accentTeal = Color(0xFF06B6D4);
  static const Color backgroundGray = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);

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

  Future<DateTime?> getLastScanFromFirestore(String labourId) async {
    final doc = await FirebaseFirestore.instance.collection('labours').doc(labourId).get();
    if (doc.exists && doc.data()?['lastScanAt'] != null) {
      return (doc.data()!['lastScanAt'] as Timestamp).toDate();
    }
    return null;
  }

  Future<void> setLastScanToFirestore(String labourId, DateTime now) async {
    await FirebaseFirestore.instance.collection('labours').doc(labourId).update({
      'lastScanAt': Timestamp.fromDate(now),
    });
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
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryBlue),
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

      // --- Firestore global cooldown logic ---
      final lastScan = await getLastScanFromFirestore(id);
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

      // Update scan timestamp in Firestore (global)
      await setLastScanToFirestore(id, now);

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
      backgroundColor: backgroundGray,
      appBar: AppBar(
        backgroundColor: cardWhite,
        elevation: 1,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SCAN ATTENDANCE',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 21,
                color: primaryBlue,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
            ),
            Container(
              height: 3,
              width: 54,
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