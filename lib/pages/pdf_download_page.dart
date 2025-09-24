import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:lapabricks/models/labour.dart';
import 'package:lapabricks/models/daily_total.dart';
import 'package:lapabricks/utils/pdf_daily_report.dart';
import 'package:lapabricks/pages/pdf_view_page.dart'; // <-- Import your PdfViewPage
import 'package:lapabricks/pages/home_page.dart'; // <-- Import your HomePage

class PdfPreviewPage extends StatefulWidget {
  final String date;
  final List<Labour> labours;
  final DailyTotal dailyTotal;

  const PdfPreviewPage({
    Key? key,
    required this.date,
    required this.labours,
    required this.dailyTotal,
  }) : super(key: key);

  @override
  State<PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<PdfPreviewPage> {
  bool _isPrintingComplete = false;

  @override
  void initState() {
    super.initState();
    _printPdf();
  }

  Future<void> _printPdf() async {
    final pdf = await generateDailyPdfDocument(
      date: widget.date,
      labours: widget.labours,
      dailyTotal: widget.dailyTotal,
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
    setState(() {
      _isPrintingComplete = true;
    });
    // Navigate to homepage
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomePage()), // <-- Change to your actual homepage widget
      (route) => false,
    );
  }

  Future<bool> _onWillPop() async {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PdfViewPage(
          date: widget.date,
          labours: widget.labours,
          dailyTotal: widget.dailyTotal,
        ),
      ),
    );
    return false; // Prevent default back navigation
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Print/Save Daily Report'),
          leading: BackButton(onPressed: () => _onWillPop()),
        ),
        body: Center(
          child: Text(
            'Preparing your PDF for print/save...',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}