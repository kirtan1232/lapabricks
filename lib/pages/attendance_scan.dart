import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lapabricks/providers/labour_store.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

class AttendanceScanPage extends StatefulWidget {
  const AttendanceScanPage({super.key});

  @override
  State<AttendanceScanPage> createState() => _AttendanceScanPageState();
}

class _AttendanceScanPageState extends State<AttendanceScanPage> {
  late final MobileScannerController _controller;
  bool _handling = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

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
    _audioPlayer.dispose();
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

  Future<void> playSound(bool success) async {
    String asset = success ? 'sounds/success.mp3' : 'sounds/failure.mp3';
    await _audioPlayer.play(AssetSource(asset));
  }

  Future<void> vibrate([bool success = true]) async {
    if (await Vibration.hasVibrator() ?? false) {
      if (success) {
        Vibration.vibrate(duration: 100, amplitude: 128);
      } else {
        Vibration.vibrate(duration: 400, amplitude: 255);
      }
    }
  }

  Future<void> _showCentralDialog({required bool success, required String message, Duration? autoClose}) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    success ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: success ? Colors.green : Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: success ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Auto close dialog after duration (default: 2 seconds)
    await Future.delayed(autoClose ?? const Duration(seconds: 2));
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
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
      // Restrict scan to 6:00 AM - 8:00 PM
      final now = DateTime.now();
      final allowedStart = DateTime(now.year, now.month, now.day, 6, 0, 0); // 6:00 AM
      final allowedEnd = DateTime(now.year, now.month, now.day, 19, 0, 0);   // 7:00 PM

      if (now.isBefore(allowedStart) || now.isAfter(allowedEnd)) {
        await playSound(false); // Play failure sound
        await vibrate(false);   // Vibrate for failure
        await _showCentralDialog(
          success: false,
          message: 'Scan not allowed!\nYou can only scan between 06:00 AM and 07:00 PM.',
          autoClose: const Duration(seconds: 3),
        );
        _handling = false;
        return;
      }

      if (value == null) return;
      if (!value.startsWith('labour:')) {
        await playSound(false);
        await vibrate(false);
        await _showCentralDialog(success: false, message: 'Invalid QR\nThis QR code is not recognized.', autoClose: const Duration(seconds: 2));
        return;
      }

      final id = value.substring('labour:'.length);
      final store = context.read<LabourStore>();
      final labour = store.byId(id);

      if (labour == null) {
        await playSound(false);
        await vibrate(false);
        await _showCentralDialog(success: false, message: 'Labour not found\nThis QR does not match any labour profile.', autoClose: const Duration(seconds: 2));
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

      // --- Firestore global cooldown logic ---
      final lastScan = await getLastScanFromFirestore(id);
      if (lastScan != null) {
        final elapsed = now.difference(lastScan);
        if (elapsed < timeout) {
          await playSound(false);
          await vibrate(false);
          await _showCentralDialog(success: false, message: 'Timeout!\nPlease wait before you can scan again.', autoClose: const Duration(seconds: 2));
          await _showCountdownDialog(timeout - elapsed);
          return;
        }
      }

      store.markAttendanceById(id);
      store.addLift(id);

      await setLastScanToFirestore(id, now);

      await playSound(true);
      await vibrate(true);
      await _controller.stop();
      if (!mounted) return;

      await _showCentralDialog(success: true, message: 'Record Updated ($occupation)', autoClose: const Duration(seconds: 2));

      await _controller.start();
    } finally {
      _handling = false;
    }
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