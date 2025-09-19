import 'package:flutter/material.dart';
import '../models/labour.dart';

class StatementPage extends StatelessWidget {
  final Labour labour;
  const StatementPage({super.key, required this.labour});

  @override
  Widget build(BuildContext context) {
    final records = labour.dailyRecords;
    final sortedKeys = records.keys.toList()..sort((a, b) => b.compareTo(a)); // newest first

    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Statement'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Work Statement', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...sortedKeys.map((date) {
            final record = records[date]!;
            return ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(date),
              subtitle: Text('Earnings: Rs ${record['earnings']}, Lifts: ${record['lifts']}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Details for $date'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Earnings: Rs ${record['earnings']}'),
                        Text('Lifts: ${record['lifts']}'),
                        Text('Total till now: Rs ${labour.dailyRecords.entries
                          .where((e) => e.key.compareTo(date) <= 0)
                          .fold(0, (a, b) => a + (b.value['earnings'] ?? 0))}'
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}