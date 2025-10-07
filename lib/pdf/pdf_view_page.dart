import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lapabricks/pdf/pdf_download_page.dart';
import 'package:pdfx/pdfx.dart';
import 'package:lapabricks/models/labour.dart';
import 'package:lapabricks/models/daily_total.dart';
import 'package:lapabricks/utils/pdf_daily_report.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:lapabricks/pdf/previous_day_report.dart'; // <-- Import the new page

class PdfViewPage extends StatefulWidget {
  final String date;
  final List<Labour> labours;
  final DailyTotal dailyTotal;

  const PdfViewPage({
    Key? key,
    required this.date,
    required this.labours,
    required this.dailyTotal,
  }) : super(key: key);

  @override
  State<PdfViewPage> createState() => _PdfViewPageState();
}

class _PdfViewPageState extends State<PdfViewPage> {
  PdfControllerPinch? _pdfController;
  String? _pdfPath;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _loadPdf();
    }
  }

  Future<void> _loadPdf() async {
    final pdfDoc = await generateDailyPdfDocument(
      date: widget.date,
      labours: widget.labours,
      dailyTotal: widget.dailyTotal,
    );
    final bytes = await pdfDoc.save();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/daily_report.pdf');
    await file.writeAsBytes(bytes);
    setState(() {
      _pdfPath = file.path;
      _pdfController = PdfControllerPinch(document: PdfDocument.openFile(file.path));
    });
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate yesterday's date in yyyy-MM-dd format
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayDate = "${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Daily Records'),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: "Previous Day Report",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PreviousDayReportPage(date: yesterdayDate),
                  ),
                );
              },
            ),
          ],
        ),
        body: PdfPreview(
          build: (format) => generateDailyPdfDocument(
            date: widget.date,
            labours: widget.labours,
            dailyTotal: widget.dailyTotal,
          ).then((pdf) => pdf.save()),
          canChangePageFormat: false,
          canDebug: false,
          allowPrinting: true,
          allowSharing: true,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "Previous Day Report",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PreviousDayReportPage(date: yesterdayDate),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: "Print/Share",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfPreviewPage(
                    date: widget.date,
                    labours: widget.labours,
                    dailyTotal: widget.dailyTotal,
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