import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/labour.dart';
import '../providers/labour_store.dart';
import 'edit_details_page.dart';

class LabourDetailPage extends StatelessWidget {
  final String labourId;
  const LabourDetailPage({super.key, required this.labourId});

  Map<String, String> parseDetails(String details) {
    final lines = details.split('\n');
    final data = <String, String>{};
    for (final line in lines) {
      final idx = line.indexOf(':');
      if (idx > -1) {
        final key = line.substring(0, idx).trim();
        final value = line.substring(idx + 1).trim();
        data[key] = value;
      }
    }
    return data;
  }

  String formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '—';
    if (phone.startsWith('+977-')) return phone;
    if (phone.startsWith('+977')) return phone.replaceFirst('+977', '+977-');
    return '+977-$phone';
  }

  String todayString() {
    final now = DateTime.now();
    return "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LabourStore>();
    final labour = store.byId(labourId);

    if (labour == null) {
      return const Scaffold(
        body: Center(child: Text('Labour not found')),
      );
    }

    final qrData = 'labour:${labour.id}';
    final parsed = parseDetails(labour.details);

    final todayEarnings = labour.dailyEarnings[todayString()] ?? 0;
    final monthlyEarnings = labour.monthlyEarnings(DateTime.now());
    final totalEarnings = labour.totalEarnings;
    final liftDetail = parsed['Lift'] ?? '—';
    final occupation = parsed['Occupation'] ?? '—';
    final plateNumber = parsed['Vehicle Plate'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Person Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditDetailsPage(labourId: labour.id),
                ),
              );
              if (result == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Person updated')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Person'),
                  content: const Text('Are you sure you want to delete this person? This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                store.deleteLabour(labour.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Person deleted')),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Center(
              child: QrImageView(
                data: qrData,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                labour.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Profile',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text('Occupation'),
              subtitle: Text(occupation),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Address'),
              subtitle: Text(parsed['Address'] ?? '—'),
            ),
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Phone'),
              subtitle: Text(formatPhone(parsed['Phone'])),
            ),
            ListTile(
              leading: const Icon(Icons.factory), // Icon for lifting goods
              title: const Text('Lift Details'),
              subtitle: Text(liftDetail),
            ),
            if (occupation == 'Driver' && plateNumber != null && plateNumber.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.local_shipping), // Truck/vehicle icon
                title: const Text('Vehicle Plate'),
                subtitle: Text(plateNumber),
              ),
            const SizedBox(height: 24),
            Text(
              'Attendance (${labour.attendance.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (labour.attendance.isEmpty)
              const Text('No attendance yet.')
            else
              ...labour.attendance
                  .map((d) => ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(
                            '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}'),
                      ))
                  .toList(),
            const SizedBox(height: 24),
            Text(
              'Payment Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ListTile(
              leading: const Icon(Icons.price_change),
              title: const Text('Per Lift Price'),
              subtitle: Text('Rs ${labour.perLiftPrice}'),
            ),
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Today\'s Earnings'),
              subtitle: Text('Rs $todayEarnings'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Monthly Earnings'),
              subtitle: Text('Rs $monthlyEarnings'),
            ),
            ListTile(
              leading: const Icon(Icons.summarize),
              title: const Text('Total Earnings'),
              subtitle: Text('Rs $totalEarnings'),
            ),
          ],
        ),
      ),
    );
  }
}