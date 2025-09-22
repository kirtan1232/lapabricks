import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:lapabricks/models/labour.dart';
import 'package:lapabricks/models/daily_total.dart';

// Returns pw.Document for previewing PDF
Future<pw.Document> generateDailyPdfDocument({
  required String date,
  required List<Labour> labours,
  required DailyTotal dailyTotal,
}) async {
  final pdfDoc = pw.Document();

  pdfDoc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context ctx) {
        return [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Lapa Bricks Daily Report - $date',
              style: pw.TextStyle(fontSize: 18),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: [
              'Name',
              'Occupation',
              'Per Lift Price',
              'Earnings',
              'Lifts',
              'Arrived',
              'Departed',
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 9,
            ),
            headerDecoration: pw.BoxDecoration(color: PdfColors.blue600),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            cellStyle: pw.TextStyle(fontSize: 8),
            data: labours.map((labour) {
              final record = labour.dailyRecords[date] ?? {};
              final att = labour.attendanceTimes[date] ?? {};
              final lifts = labour.occupation == 'Staff' ? '-' : (record['lifts'] ?? 0).toString();
              final earnings = (record['earnings'] ?? 0).toString();
              final arrival = att['arrival'] != null ? _formatTime(att['arrival']!) : '-';
              final departure = att['departure'] != null ? _formatTime(att['departure']!) : '-';
              final perLiftPrice = labour.occupation == 'Staff'
                  ? (labour.dailyIncome != null ? 'Rs ${labour.dailyIncome}' : '-')
                  : 'Rs ${labour.perLiftPrice}';
              return [
                labour.name,
                labour.occupation,
                perLiftPrice,
                'Rs $earnings',
                lifts,
                arrival,
                departure,
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            '--- Daily Totals ---',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Bullet(text: "Labour: Lifts ${dailyTotal.labourTotalLifts}, Earnings Rs ${dailyTotal.labourTotalEarnings}", style: pw.TextStyle(fontSize: 9)),
          pw.Bullet(text: "Driver: Lifts ${dailyTotal.driverTotalLifts}, Earnings Rs ${dailyTotal.driverTotalEarnings}", style: pw.TextStyle(fontSize: 9)),
          pw.Bullet(text: "Staff: Earnings Rs ${dailyTotal.staffTotalEarnings}", style: pw.TextStyle(fontSize: 9)),
          pw.Bullet(text: "Overall: Lifts ${dailyTotal.overallTotalLifts}, Earnings Rs ${dailyTotal.overallTotalEarnings}", style: pw.TextStyle(fontSize: 9)),
        ];
      },
    ),
  );

  return pdfDoc;
}

// Helper to format time for PDF
String _formatTime(DateTime dt) {
  int hour = dt.hour % 12;
  if (hour == 0) hour = 12;
  final min = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour < 12 ? 'AM' : 'PM';
  return '$hour:$min $period';
}