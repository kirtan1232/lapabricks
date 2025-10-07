import 'package:lapabricks/models/daily_total.dart';
import 'package:lapabricks/models/labour.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

// Load NotoSans font for Unicode support
Future<pw.Font> _loadUnicodeFont() async {
  final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
  return pw.Font.ttf(fontData);
}

Future<pw.Document> generateDailyPdfDocument({
  required String date,
  required List<Labour> labours,
  required DailyTotal dailyTotal,
}) async {
  final pdfDoc = pw.Document();
  final unicodeFont = await _loadUnicodeFont();

  // Helper to get brick type from Labour, fallback to details field
  String? getBrickType(Labour l) {
    if (l.brickType != null && l.brickType!.isNotEmpty) return l.brickType;
    final details = l.details.toLowerCase();
    if (details.contains('brick type: kacho brick')) return 'Kacho Brick';
    if (details.contains('brick type: pako brick')) return 'Pako Brick';
    return null;
  }

  void addPage({
    required String title,
    required bool Function(Labour) filter,
    bool forStaff = false,
  }) {
    final filtered = labours.where(filter).toList();

    int totalLifts = 0;
    int totalBrickLifts = 0;
    int totalEarnings = 0;
    final List<List<String>> tableData = [];

    for (final labour in filtered) {
      final record = labour.dailyRecords[date] ?? {};
      final att = labour.attendanceTimes[date] ?? {};
      final earningsStr = (record['earnings'] ?? 0).toString();
      final earningsNum = int.tryParse(earningsStr) ?? 0;
      final arrival = att['arrival'] != null
          ? _formatTime(att['arrival']!)
          : '-';
      final departure = att['departure'] != null
          ? _formatTime(att['departure']!)
          : '-';

      if (forStaff) {
        totalEarnings += earningsNum;
        tableData.add([
          labour.name,
          labour.occupation,
          'Rs $earningsStr',
          arrival,
          departure,
        ]);
      } else {
        final liftsStr = (record['lifts'] ?? 0).toString();
        final liftsNum = int.tryParse(liftsStr) ?? 0;
        final perLiftPrice = (labour.perLiftPrice != null)
            ? 'Rs ${labour.perLiftPrice}'
            : '-';

        int liftDetail = 1;
        final details = labour.details ?? '';
        final regex = RegExp(r'Lift:\s*(\d+)');
        final match = regex.firstMatch(details);
        if (match != null) {
          liftDetail = int.tryParse(match.group(1) ?? '') ?? 1;
        }

        String nameWithLift = '${labour.name} ($liftDetail)';
        final brickLiftNum = liftDetail * liftsNum;
        final brickLiftStr = brickLiftNum.toString();

        totalLifts += liftsNum;
        totalBrickLifts += brickLiftNum;
        totalEarnings += earningsNum;

        tableData.add([
          nameWithLift,
          labour.occupation,
          perLiftPrice,
          liftsStr,
          brickLiftStr,
          'Rs $earningsStr',
          arrival,
          departure,
        ]);
      }
    }

    // Add total row at the end
    if (forStaff) {
      tableData.add(['Total', '', 'Rs $totalEarnings', '', '']);
    } else {
      tableData.add([
        'Total',
        '',
        '',
        totalLifts.toString(),
        totalBrickLifts.toString(),
        'Rs $totalEarnings',
        '',
        '',
      ]);
    }

    pdfDoc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Lapa Bricks Daily Report - $date\n$title',
                style: pw.TextStyle(fontSize: 18, font: unicodeFont),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
              tableWidth: pw.TableWidth.max,
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.blue600),
                  children: forStaff
                      ? [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Text(
                              'Name',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                fontSize: 9,
                                font: unicodeFont,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Text(
                              'Occupation',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                fontSize: 9,
                                font: unicodeFont,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Text(
                              'Earnings',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                fontSize: 9,
                                font: unicodeFont,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Text(
                              'Arrived',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                fontSize: 9,
                                font: unicodeFont,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Text(
                              'Departed',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                fontSize: 9,
                                font: unicodeFont,
                              ),
                            ),
                          ),
                        ]
                      : [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Text(
                              'Name',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                fontSize: 9,
                                font: unicodeFont,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Text(
                              'Occupation',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                fontSize: 9,
                                font: unicodeFont,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Text(
                              'Per Lift Price',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                fontSize: 9,
                                font: unicodeFont,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Text(
                              'Lifts',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                fontSize: 9,
                                font: unicodeFont,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Text(
                              'Brick Lift',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                fontSize: 9,
                                font: unicodeFont,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Text(
                              'Earnings',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                fontSize: 9,
                                font: unicodeFont,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Text(
                              'Arrived',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                fontSize: 9,
                                font: unicodeFont,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(2),
                            child: pw.Text(
                              'Departed',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                fontSize: 9,
                                font: unicodeFont,
                              ),
                            ),
                          ),
                        ],
                ),
                ...List.generate(tableData.length, (rowIdx) {
                  final row = tableData[rowIdx];
                  final isTotalRow = rowIdx == tableData.length - 1;
                  return pw.TableRow(
                    decoration: isTotalRow
                        ? pw.BoxDecoration(color: PdfColors.grey300)
                        : null,
                    children: List.generate(row.length, (colIdx) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 2,
                        ),
                        child: pw.Text(
                          row[colIdx],
                          style: isTotalRow
                              ? pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 9,
                                  font: unicodeFont,
                                )
                              : pw.TextStyle(
                                  fontSize: 8,
                                  font: unicodeFont,
                                ),
                          textAlign: (forStaff
                              ? (colIdx == 2
                                    ? pw.TextAlign.right
                                    : pw.TextAlign.left)
                              : (colIdx >= 3 && colIdx <= 5)
                              ? pw.TextAlign.right
                              : pw.TextAlign.left),
                        ),
                      );
                    }),
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Text(
              'Page End (पृष्ठ अन्त्य)', // End 
              style: pw.TextStyle(font: unicodeFont, fontSize: 14),
            ),
          ];
        },
      ),
    );
  }

  addPage(
    title: "Kacho (काचो)Brick Labours",
    filter: (l) => l.occupation == "Labour" && getBrickType(l) == "Kacho Brick",
  );
  addPage(
    title: "Pako (पाको)Brick Labours",
    filter: (l) => l.occupation == "Labour" && getBrickType(l) == "Pako Brick",
  );
  addPage(title: "Drivers(गाडी)", filter: (l) => l.occupation == "Driver");
  addPage(
    title: "Staff(स्ताफ्फ़)",
    filter: (l) => l.occupation == "Staff",
    forStaff: true,
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