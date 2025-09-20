import 'package:flutter/material.dart';
import 'package:lapabricks/models/labour.dart';

class StatementPage extends StatelessWidget {
  final Labour labour;
  const StatementPage({super.key, required this.labour});

  @override
  Widget build(BuildContext context) {
    final records = labour.dailyRecords;
    final sortedKeys = records.keys.toList()..sort((a, b) => b.compareTo(a)); // newest first

    const Color orangeAccent = Color(0xFFFF9800);
    const Color cream = Color(0xFFFFF6E5);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: orangeAccent,
        title: const Text('Work Statement'),
        elevation: 2,
      ),
      body: sortedKeys.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: orangeAccent, size: 60),
                  const SizedBox(height: 14),
                  Text(
                    "No records yet.",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: sortedKeys.length,
              itemBuilder: (context, idx) {
                final date = sortedKeys[idx];
                final record = records[date]!;
                final totalTillNow = labour.dailyRecords.entries
                    .where((e) => e.key.compareTo(date) <= 0)
                    .fold(0, (a, b) => a + (b.value['earnings'] ?? 0));
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 3,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                    leading: CircleAvatar(
                      backgroundColor: orangeAccent.withOpacity(0.14),
                      child: const Icon(Icons.calendar_today, color: orangeAccent),
                    ),
                    title: Text(
                      date,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Earnings: Rs ${record['earnings']}',
                              style: const TextStyle(color: Colors.black87)),
                          Text('Lifts: ${record['lifts']}',
                              style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: orangeAccent, size: 18),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                        builder: (_) => Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: orangeAccent.withOpacity(0.14),
                                    child: const Icon(Icons.calendar_today, color: orangeAccent),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    date,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: orangeAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Text('Earnings: Rs ${record['earnings']}',
                                  style: const TextStyle(fontSize: 16)),
                              Text('Lifts: ${record['lifts']}',
                                  style: const TextStyle(fontSize: 16)),
                              const Divider(height: 26),
                              Text(
                                'Total till now: Rs $totalTillNow',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
                              ),
                              const SizedBox(height: 9),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: TextButton.icon(
                                  icon: const Icon(Icons.close, color: orangeAccent),
                                  label: const Text('Close'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: orangeAccent,
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