import 'package:flutter/material.dart';
import 'package:lapabricks/models/labour.dart';

class StatementPage extends StatelessWidget {
  final Labour labour;
  const StatementPage({super.key, required this.labour});

  String? getArrivalTime(String date) {
    final times = labour.attendanceTimes[date];
    if (times != null && times['arrival'] != null) {
      final t = times['arrival']!;
      return "${formatTime(t)}${t.hour < 12 ? ' AM' : ' PM'}";
    }
    return null;
  }

  String? getDepartureTime(String date) {
    final times = labour.attendanceTimes[date];
    if (times != null && times['departure'] != null) {
      final t = times['departure']!;
      return "${formatTime(t)}${t.hour < 12 ? ' AM' : ' PM'}";
    }
    return null;
  }

  String formatTime(DateTime d) {
    int hour = d.hour % 12;
    if (hour == 0) hour = 12;
    final min = d.minute.toString().padLeft(2, '0');
    return "$hour:$min";
  }

  int getLiftDetail(String details) {
    final regex = RegExp(r'Lift:\s*(\d+)');
    final match = regex.firstMatch(details);
    if (match != null) return int.tryParse(match.group(1) ?? '1') ?? 1;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final records = labour.dailyRecords;
    final sortedKeys = records.keys.toList()..sort((a, b) => b.compareTo(a));
    final liftDetail = getLiftDetail(labour.details);

    const Color primaryBlue = Color(0xFF2563EB);
    const Color lightBlue = Color(0xFF3B82F6);
    const Color accentTeal = Color(0xFF06B6D4);
    const Color backgroundGray = Color(0xFFF8FAFC);
    const Color cardWhite = Color(0xFFFFFFFF);
    const Color darkGray = Color(0xFF1E293B);
    const Color lightGray = Color(0xFF64748B);

    // Calculate running total bricks
    int runningBricksTotal = 0;

    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        backgroundColor: cardWhite,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        titleSpacing: 0,
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'WORK STATEMENT',
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
      ),
      body: sortedKeys.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: primaryBlue, size: 60),
                  const SizedBox(height: 14),
                  Text(
                    "No records yet.",
                    style: TextStyle(
                      fontSize: 19,
                      color: lightGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              itemCount: sortedKeys.length,
              itemBuilder: (context, idx) {
                final date = sortedKeys[idx];
                final record = records[date]!;
                final earnings = record['earnings'] ?? 0;
                final lifts = record['lifts'] ?? 0;
                final arrived = getArrivalTime(date);
                final depart = getDepartureTime(date);

                final bricksLifted = (labour.occupation != 'Staff') ? (lifts * liftDetail) : 0;
                runningBricksTotal += bricksLifted;

                final totalTillNow = labour.dailyRecords.entries
                    .where((e) => e.key.compareTo(date) <= 0)
                    .fold(0, (a, b) => a + (b.value['earnings'] ?? 0));

                int totalBricksTillNow = 0;
                labour.dailyRecords.entries
                    .where((e) => e.key.compareTo(date) <= 0)
                    .forEach((e) {
                  if (labour.occupation != 'Staff') {
                    totalBricksTillNow += (e.value['lifts'] ?? 0) * liftDetail;
                  }
                });

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 4,
                  color: cardWhite,
                  margin: const EdgeInsets.only(bottom: 18),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    leading: CircleAvatar(
                      backgroundColor: primaryBlue.withOpacity(0.14),
                      child: const Icon(Icons.calendar_today, color: primaryBlue),
                    ),
                    title: Text(
                      date,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: darkGray),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Earnings: Rs $earnings',
                              style: const TextStyle(color: darkGray, fontWeight: FontWeight.w500)),
                          if (labour.occupation != 'Staff')
                            Text('Lifts: $lifts',
                                style: const TextStyle(color: lightGray, fontWeight: FontWeight.w500)),
                          if (arrived != null)
                            Text('Arrived: $arrived',
                                style: const TextStyle(color: darkGray, fontWeight: FontWeight.w500)),
                          if (depart != null)
                            Text('Departed: $depart',
                                style: const TextStyle(color: lightGray, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, color: primaryBlue, size: 18),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: cardWhite,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (_) => Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: accentTeal.withOpacity(0.13),
                                    child: const Icon(Icons.calendar_today, color: accentTeal),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    date,
                                    style: TextStyle(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 19,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Text('Earnings: Rs $earnings',
                                  style: const TextStyle(fontSize: 16, color: darkGray)),
                              if (labour.occupation != 'Staff')
                                Text('Lifts: $lifts',
                                    style: const TextStyle(fontSize: 16, color: lightGray)),
                              if (arrived != null)
                                Text('Arrived: $arrived',
                                    style: const TextStyle(fontSize: 15, color: darkGray)),
                              if (depart != null)
                                Text('Departed: $depart',
                                    style: const TextStyle(fontSize: 15, color: lightGray)),

                              if (labour.occupation != 'Staff') ...[
                                const Divider(height: 28),
                                Row(
                                  children: [
                                    Icon(Icons.widgets, color: accentTeal),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Bricks Lifted: $bricksLifted',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: accentTeal,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.all_inbox, color: primaryBlue),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Total Bricks Till Now: $totalBricksTillNow',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryBlue,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const Divider(height: 30),
                              Text(
                                'Total till now: Rs $totalTillNow',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16, color: primaryBlue),
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
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}