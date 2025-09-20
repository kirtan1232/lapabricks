import 'package:flutter/material.dart';
import 'package:lapabricks/pages/edit_details_page.dart';
import 'package:lapabricks/pages/statement_page.dart';
import 'package:lapabricks/providers/labour_store.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

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

    const Color cream = Color(0xFFFFF6E5);
    const Color orangeAccent = Color(0xFFFF9800);
    const Color lightOrange = Color(0xFFFFB74D);

    if (labour == null) {
      return const Scaffold(body: Center(child: Text('Labour not found')));
    }

    final qrData = 'labour:${labour.id}';
    final parsed = parseDetails(labour.details);

    final todayStr = todayString();
    final todayRecord = labour.dailyRecords[todayStr] ?? {};
    final todayAttendance = labour.attendance
        .where(
          (d) =>
              d.year == DateTime.now().year &&
              d.month == DateTime.now().month &&
              d.day == DateTime.now().day,
        )
        .toList();

    final todayEarnings = todayRecord['earnings'] ?? 0;
    final todayLifts = todayRecord['lifts'] ?? 0;
    final monthlyEarnings = labour.monthlyEarnings(DateTime.now());
    final totalEarnings = labour.totalEarnings;
    final liftDetail = parsed['Lift'] ?? '—';
    final occupation = parsed['Occupation'] ?? '—';
    final plateNumber = parsed['Vehicle Plate'];
    final brickType = parsed['Brick Type'] ?? '—';

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: orangeAccent,
        title: const Text('Person Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.stacked_line_chart),
            tooltip: 'Statement',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StatementPage(labour: labour),
                ),
              );
            },
          ),
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
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Person updated')));
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
                  content: const Text(
                    'Are you sure you want to delete this person? This cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                store.deleteLabour(labour.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Person deleted')));
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth < 550
              ? constraints.maxWidth * 0.98
              : constraints.maxWidth < 1000
              ? 530
              : 700;
          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 14,
                ),
                children: [
                  Center(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            QrImageView(
                              data: qrData,
                              size: 200, // Bigger QR
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              labour.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: orangeAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 23,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Profile',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Card(
                    elevation: 1,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.badge, color: orangeAccent),
                          title: const Text('Occupation'),
                          subtitle: Text(occupation),
                        ),
                        Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.home, color: lightOrange),
                          title: const Text('Address'),
                          subtitle: Text(parsed['Address'] ?? '—'),
                        ),
                        Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.phone, color: Colors.green),
                          title: const Text('Phone'),
                          subtitle: Text(formatPhone(parsed['Phone'])),
                        ),
                        Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.factory,
                            color: Colors.deepPurple,
                          ),
                          title: const Text('Lift Details'),
                          subtitle: Text(liftDetail),
                        ),
                        if (occupation == 'Driver' &&
                            plateNumber != null &&
                            plateNumber.isNotEmpty) ...[
                          Divider(height: 1),
                          ListTile(
                            leading: Icon(
                              Icons.local_shipping,
                              color: Colors.blueAccent,
                            ),
                            title: const Text('Vehicle Plate'),
                            subtitle: Text(plateNumber),
                          ),
                        ],
                        Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.category,
                            color: Colors.pinkAccent,
                          ),
                          title: const Text('Brick Type'),
                          subtitle: Text(brickType),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Today\'s Attendance',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Card(
                    elevation: 1,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: todayAttendance.isEmpty
                          ? ListTile(
                              leading: Icon(
                                Icons.info_outline,
                                color: Colors.redAccent,
                              ),
                              title: const Text('No Attendance'),
                            )
                          : ListTile(
                              leading: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              title: Text(
                                '${DateTime.now().day.toString().padLeft(2, '0')}-'
                                '${DateTime.now().month.toString().padLeft(2, '0')}-'
                                '${DateTime.now().year}',
                              ),
                              subtitle: Text('Attendance marked for today'),
                            ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Payment Summary',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Card(
                    elevation: 1,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            Icons.price_change,
                            color: Colors.green,
                          ),
                          title: const Text('Per Lift Price'),
                          subtitle: Text('Rs ${labour.perLiftPrice}'),
                        ),
                        Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.today, color: lightOrange),
                          title: const Text("Today's Earnings"),
                          subtitle: Text(
                            'Rs $todayEarnings  (Lifts: $todayLifts)',
                          ),
                        ),
                        Divider(height: 1),
                        ListTile(
                          leading: Icon(
                            Icons.calendar_today,
                            color: Colors.blueAccent,
                          ),
                          title: const Text('Monthly Earnings'),
                          subtitle: Text('Rs $monthlyEarnings'),
                        ),
                        Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.summarize, color: Colors.purple),
                          title: const Text('Total Earnings'),
                          subtitle: Text('Rs $totalEarnings'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
