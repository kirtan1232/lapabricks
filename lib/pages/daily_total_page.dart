import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapabricks/models/daily_total.dart';

class DailyTotalPage extends StatefulWidget {
  const DailyTotalPage({super.key});

  @override
  State<DailyTotalPage> createState() => _DailyTotalPageState();
}

class _DailyTotalWithCalculated {
  final String date;
  final int labourTotalLifts;
  final int labourTotalEarnings;
  final int driverTotalLifts;
  final int driverTotalEarnings;
  final int staffTotalEarnings;
  final int overallTotalLifts;
  final int overallTotalEarnings;
  final int overallTotalBricks;

  _DailyTotalWithCalculated(
      {required this.date,
      required this.labourTotalLifts,
      required this.labourTotalEarnings,
      required this.driverTotalLifts,
      required this.driverTotalEarnings,
      required this.staffTotalEarnings,
      required this.overallTotalLifts,
      required this.overallTotalEarnings,
      required this.overallTotalBricks});
}

class _DailyTotalPageState extends State<DailyTotalPage> {
  late Future<List<_DailyTotalWithCalculated>> _futureData;

  @override
  void initState() {
    super.initState();
    _futureData = _fetchAllData();
  }

  Future<List<_DailyTotalWithCalculated>> _fetchAllData() async {
    final dailyTotalSnap =
        await FirebaseFirestore.instance.collection('daily_total').get();
    final laboursSnap =
        await FirebaseFirestore.instance.collection('labours').get();

    final labours = laboursSnap.docs.map((doc) => doc.data()).toList();

    List<_DailyTotalWithCalculated> result = [];
    for (final doc in dailyTotalSnap.docs) {
      final dt = DailyTotal.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      final calculated = _calculateAll(dt.date, labours);
      result.add(calculated);
    }
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  _DailyTotalWithCalculated _calculateAll(String date, List<Map<String, dynamic>> labours) {
    int labourTotalLifts = 0;
    int labourTotalEarnings = 0;
    int driverTotalLifts = 0;
    int driverTotalEarnings = 0;
    int staffTotalEarnings = 0;
    int overallTotalLifts = 0;
    int overallTotalEarnings = 0;
    int overallTotalBricks = 0;

    for (final data in labours) {
      final occupation = data['occupation'] as String? ?? '';
      final details = data['details'] as String? ?? '';
      final dailyRecords = Map<String, dynamic>.from(data['dailyRecords'] ?? {});
      int liftDetail = 1;
      final regex = RegExp(r'Lift:\s*(\d+)');
      final match = regex.firstMatch(details);
      if (match != null) {
        liftDetail = int.tryParse(match.group(1) ?? '') ?? 1;
      }
      final record = dailyRecords[date] as Map<String, dynamic>?;
      if (record != null) {
        final lifts = (record['lifts'] ?? 0) as int;
        final earnings = (record['earnings'] ?? 0) as int;
        final bricks = liftDetail * lifts;

        if (occupation == 'Labour') {
          labourTotalLifts += lifts;
          labourTotalEarnings += earnings;
        } else if (occupation == 'Driver') {
          driverTotalLifts += lifts;
          driverTotalEarnings += earnings;
        } else if (occupation == 'Staff') {
          staffTotalEarnings += earnings;
        }

        overallTotalLifts += lifts;
        overallTotalEarnings += earnings;
        overallTotalBricks += bricks;
      }
    }

    return _DailyTotalWithCalculated(
      date: date,
      labourTotalLifts: labourTotalLifts,
      labourTotalEarnings: labourTotalEarnings,
      driverTotalLifts: driverTotalLifts,
      driverTotalEarnings: driverTotalEarnings,
      staffTotalEarnings: staffTotalEarnings,
      overallTotalLifts: overallTotalLifts,
      overallTotalEarnings: overallTotalEarnings,
      overallTotalBricks: overallTotalBricks,
    );
  }

  void _reloadAll() {
    setState(() {
      _futureData = _fetchAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2563EB);
    const Color accentTeal = Color(0xFF06B6D4);
    const Color backgroundGray = Color(0xFFF8FAFC);
    const Color cardWhite = Color(0xFFFFFFFF);
    const Color darkGray = Color(0xFF1E293B);
    const Color lightGray = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        backgroundColor: cardWhite,
        elevation: 0,
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DAILY TOTALS',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: primaryBlue,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.08),
                    ),
                  ],
                ),
              ),
              Container(
                height: 3,
                width: 56,
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
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: accentTeal),
            tooltip: "Reload",
            onPressed: _reloadAll,
          ),
        ],
      ),
      body: FutureBuilder<List<_DailyTotalWithCalculated>>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: primaryBlue, size: 60),
                  const SizedBox(height: 14),
                  Text(
                    "No daily totals yet.",
                    style: TextStyle(
                      fontSize: 19,
                      color: lightGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }
          final dailyTotals = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            itemCount: dailyTotals.length,
            itemBuilder: (context, idx) {
              final dt = dailyTotals[idx];
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                elevation: 4,
                color: cardWhite,
                margin: const EdgeInsets.only(bottom: 18),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 20),
                  leading: CircleAvatar(
                    backgroundColor: primaryBlue.withOpacity(0.14),
                    child: const Icon(Icons.calendar_today, color: primaryBlue),
                  ),
                  title: Text(
                    dt.date,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: darkGray),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Text(
                          'Lifts: ',
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${dt.overallTotalLifts}',
                          style: const TextStyle(
                            color: Color(0xFF06B6D4),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Icon(Icons.all_inbox, color: accentTeal, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'Bricks: ',
                          style: TextStyle(
                            color: accentTeal,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${dt.overallTotalBricks}',
                          style: const TextStyle(
                            color: Color(0xFF06B6D4),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios_rounded,
                      color: primaryBlue, size: 18),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: cardWhite,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (_) => SafeArea(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 22,
                              right: 22,
                              top: 22,
                              bottom:
                                  MediaQuery.of(context).viewInsets.bottom + 22,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          accentTeal.withOpacity(0.13),
                                      child: const Icon(Icons.calendar_today,
                                          color: accentTeal),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      dt.date,
                                      style: TextStyle(
                                        color: primaryBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 19,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                _detailRow(
                                    'Labour',
                                    dt.labourTotalLifts,
                                    dt.labourTotalEarnings,
                                    darkGray,
                                    lightGray,
                                    liftsColor: primaryBlue),
                                _detailRow(
                                    'Driver',
                                    dt.driverTotalLifts,
                                    dt.driverTotalEarnings,
                                    darkGray,
                                    lightGray,
                                    liftsColor: primaryBlue),
                                _staffDetailRow(dt.staffTotalEarnings, darkGray,
                                    lightGray),
                                const Divider(height: 30),
                                _detailRow(
                                    'Overall',
                                    dt.overallTotalLifts,
                                    dt.overallTotalEarnings,
                                    primaryBlue,
                                    accentTeal,
                                    bold: true,
                                    liftsColor: accentTeal),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.all_inbox, color: accentTeal),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Bricks:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: accentTeal,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${dt.overallTotalBricks}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF06B6D4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: TextButton.icon(
                                    icon: Icon(Icons.close, color: accentTeal),
                                    label: const Text('Close'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: accentTeal,
                                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _detailRow(
    String label,
    int lifts,
    int earnings,
    Color color1,
    Color color2, {
    bool bold = false,
    Color liftsColor = Colors.black,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: color1,
              fontSize: bold ? 16 : 15,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Lifts: ',
                style: TextStyle(
                  color: color2,
                  fontWeight: FontWeight.w600,
                  fontSize: bold ? 15 : 13,
                ),
              ),
              Text(
                '$lifts',
                style: TextStyle(
                  color: liftsColor,
                  fontWeight: FontWeight.w900,
                  fontSize: bold ? 16 : 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Earnings: Rs $earnings',
            style: TextStyle(
              color: color2,
              fontWeight: FontWeight.w600,
              fontSize: bold ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _staffDetailRow(int earnings, Color color1, Color color2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Staff:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color1,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Earnings: Rs $earnings',
            style: TextStyle(
              color: color2,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}