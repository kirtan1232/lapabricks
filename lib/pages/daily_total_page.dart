import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapabricks/models/daily_total.dart';

class DailyTotalPage extends StatelessWidget {
  const DailyTotalPage({super.key});

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
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('daily_total')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
          final dailyTotals = snapshot.data!.docs
            .map((doc) => DailyTotal.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList();
          dailyTotals.sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            itemCount: dailyTotals.length,
            itemBuilder: (context, idx) {
              final dt = dailyTotals[idx];
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
                    dt.date,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: darkGray),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _overallRow(
                      dt.overallTotalLifts,
                      dt.overallTotalEarnings,
                      primaryBlue,
                      accentTeal
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, color: primaryBlue, size: 18),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: cardWhite,
                      isScrollControlled: true, // <-- Important: allows full height and scrolling!
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                      builder: (_) => SafeArea(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 22,
                              right: 22,
                              top: 22,
                              // For bottom, add viewInsets to handle keyboard if needed and safe area
                              bottom: MediaQuery.of(context).viewInsets.bottom + 22,
                            ),
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
                                _detailRow('Labour', dt.labourTotalLifts, dt.labourTotalEarnings, darkGray, lightGray),
                                _detailRow('Driver', dt.driverTotalLifts, dt.driverTotalEarnings, darkGray, lightGray),
                                _staffDetailRow(dt.staffTotalEarnings, darkGray, lightGray),
                                const Divider(height: 30),
                                _detailRow('Overall', dt.overallTotalLifts, dt.overallTotalEarnings, primaryBlue, accentTeal, bold: true),
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

  // Only for main page: overall on two rows
  Widget _overallRow(int lifts, int earnings, Color color1, Color color2) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overall:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color1,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Lifts: $lifts',
          style: TextStyle(
            color: color2,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Earnings: Rs $earnings',
          style: TextStyle(
            color: color2,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  // For Labour/Driver/Overall (details bottom sheet): Lifts and Earnings on separate rows
  Widget _detailRow(String label, int lifts, int earnings, Color color1, Color color2, {bool bold = false}) {
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
          Text(
            'Lifts: $lifts',
            style: TextStyle(
              color: color2,
              fontWeight: FontWeight.w600,
              fontSize: bold ? 15 : 13,
            ),
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

  // For Staff (details bottom sheet): no lifts
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