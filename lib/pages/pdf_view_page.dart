import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lapabricks/pages/pdf_download_page.dart';
import 'package:pdfx/pdfx.dart';
import 'package:lapabricks/models/labour.dart';
import 'package:lapabricks/models/daily_total.dart';
import 'package:lapabricks/utils/pdf_daily_report.dart';
import 'package:path_provider/path_provider.dart';

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
    _loadPdf();
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Records'),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
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
          ? Center(child: CircularProgressIndicator())
          : PdfViewPinch(
              controller: _pdfController!,
              scrollDirection: Axis.vertical,
            ),
    );
  }
}