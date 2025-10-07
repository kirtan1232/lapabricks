import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapabricks/models/labour.dart';
import 'package:lapabricks/models/daily_total.dart';
import 'package:lapabricks/utils/pdf_daily_report.dart';
import 'package:pdfx/pdfx.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lapabricks/pdf/pdf_download_page.dart'; // <-- Import your PdfPreviewPage

class PreviousDayReportPage extends StatefulWidget {
  final String date;
  const PreviousDayReportPage({super.key, required this.date});

  @override
  State<PreviousDayReportPage> createState() => _PreviousDayReportPageState();
}

class _PreviousDayReportPageState extends State<PreviousDayReportPage> {
  PdfControllerPinch? _pdfController;
  String? _pdfPath;
  List<Labour>? labours;
  DailyTotal? dailyTotal;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Fetch daily_total for previous date
      final dailyTotalSnap = await FirebaseFirestore.instance
          .collection('daily_total')
          .doc(widget.date)
          .get();

      if (!dailyTotalSnap.exists) {
        setState(() {
          _error = "No report found for previous day.";
          _loading = false;
        });
        return;
      }
      final dailyTotalObj = DailyTotal.fromMap(
          dailyTotalSnap.id, dailyTotalSnap.data() as Map<String, dynamic>);

      // Fetch all labours
      final laboursSnap = await FirebaseFirestore.instance
          .collection('labours')
          .get();
      final laboursList = laboursSnap.docs
          .map((doc) => Labour.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Sort labours alphabetically by name
      laboursList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      // Generate PDF
      if (!kIsWeb) {
        final pdfDoc = await generateDailyPdfDocument(
          date: widget.date,
          labours: laboursList,
          dailyTotal: dailyTotalObj,
        );
        final bytes = await pdfDoc.save();
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/previous_day_report.pdf');
        await file.writeAsBytes(bytes);
        _pdfPath = file.path;
        _pdfController = PdfControllerPinch(document: PdfDocument.openFile(file.path));
      }

      setState(() {
        labours = laboursList;
        dailyTotal = dailyTotalObj;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error loading report: $e";
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Previous Day Report')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Previous Day Report')),
        body: Center(child: Text(_error!)),
      );
    }
    if (labours == null || dailyTotal == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Previous Day Report')),
        body: const Center(child: Text('No report found for previous day.')),
      );
    }

    // Web: show PdfPreview
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Previous Day Report')),
        body: PdfPreview(
          build: (format) => generateDailyPdfDocument(
            date: widget.date,
            labours: labours!,
            dailyTotal: dailyTotal!,
          ).then((pdf) => pdf.save()),
          canChangePageFormat: false,
          canDebug: false,
          allowPrinting: true,
          allowSharing: true,
        ),
      );
    }

    // Mobile: show PdfViewPinch with Print/Share icon in AppBar
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previous Day Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: "Print/Share",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfPreviewPage(
                    date: widget.date,
                    labours: labours!,
                    dailyTotal: dailyTotal!,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _pdfController == null
          ? const Center(child: CircularProgressIndicator())
          : PdfViewPinch(
              controller: _pdfController!,
              scrollDirection: Axis.vertical,
            ),
    );
  }
}