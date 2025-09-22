import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:lapabricks/models/labour.dart';
import 'package:lapabricks/models/daily_total.dart';
import 'package:lapabricks/utils/pdf_daily_report.dart';

class PdfPreviewPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview PDF'),
        leading: BackButton(),
      ),
      body: PdfPreview(
        build: (format) async =>
            (await generateDailyPdfDocument(
              date: date,
              labours: labours,
              dailyTotal: dailyTotal,
            ))
            .save(),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
      ),
    );
  }
}