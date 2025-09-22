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

    const Color primaryBlue = Color(0xFF2563EB);
    const Color lightBlue = Color(0xFF3B82F6);
    const Color accentTeal = Color(0xFF06B6D4);
    const Color backgroundGray = Color(0xFFF8FAFC);
    const Color cardWhite = Color(0xFFFFFFFF);
    const Color darkGray = Color(0xFF1E293B);
    const Color lightGray = Color(0xFF64748B);

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
    final todayLifts = labour.occupation != 'Staff' ? (todayRecord['lifts'] ?? 0) : null;
    final monthlyEarnings = labour.monthlyEarnings(DateTime.now());
    final totalEarnings = labour.totalEarnings;
    final liftDetail = parsed['Lift'] ?? '—';
    final occupation = parsed['Occupation'] ?? '—';
    final plateNumber = parsed['Vehicle Plate'];
    final brickType = parsed['Brick Type'] ?? '—';

    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        backgroundColor: cardWhite,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Person Details',
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.stacked_line_chart),
            tooltip: 'Statement',
            color: accentTeal,
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
            color: primaryBlue,
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
            color: Colors.redAccent,
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double maxWidth = constraints.maxWidth < 550
                ? constraints.maxWidth * 0.98
                : constraints.maxWidth < 1000
                    ? 540
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
                    // Top QR + Name Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: cardWhite,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 24,
                        ),
                        child: Column(
                          children: [
                            QrImageView(
                              data: qrData,
                              size: 130,
                              backgroundColor: cardWhite,
                            ),
                            const SizedBox(height: 18),
                            LayoutBuilder(builder: (context, constraints) {
                              return Column(
                                children: [
                                  // Name (responsive)
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: constraints.maxWidth - 48,
                                    ),
                                    child: Text(
                                      labour.name,
                                      style: TextStyle(
                                        color: primaryBlue,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 28,
                                        letterSpacing: 1.2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Only show Lift Details if not Staff
                                  if (labour.occupation != 'Staff')
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.factory,
                                          color: lightBlue,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          liftDetail,
                                          style: TextStyle(
                                            color: lightBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              );
                            }),
                            Container(
                              height: 3,
                              width: 60,
                              margin: const EdgeInsets.only(top: 6),
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
                    const SizedBox(height: 22),

                    // Profile Info
                    Text(
                      'Profile',
                      style: TextStyle(
                        color: accentTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      elevation: 1,
                      color: cardWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.badge, color: primaryBlue),
                            title: const Text('Occupation'),
                            subtitle: Text(occupation),
                          ),
                          Divider(height: 1),
                          ListTile(
                            leading: Icon(Icons.home, color: accentTeal),
                            title: const Text('Address'),
                            subtitle: Text(parsed['Address'] ?? '—'),
                          ),
                          Divider(height: 1),
                          ListTile(
                            leading: Icon(Icons.phone, color: Colors.green),
                            title: const Text('Phone'),
                            subtitle: Text(formatPhone(parsed['Phone'])),
                          ),
                          // Show Lift Details only if not Staff
                          if (labour.occupation != 'Staff') ...[
                            Divider(height: 1),
                            ListTile(
                              leading: Icon(Icons.factory, color: lightBlue),
                              title: const Text('Lift Details'),
                              subtitle: Text(liftDetail),
                            ),
                          ],
                          if (occupation == 'Driver' &&
                              plateNumber != null &&
                              plateNumber.isNotEmpty) ...[
                            Divider(height: 1),
                            ListTile(
                              leading: Icon(
                                Icons.local_shipping,
                                color: primaryBlue,
                              ),
                              title: const Text('Vehicle Plate'),
                              subtitle: Text(plateNumber),
                            ),
                          ],
                          Divider(height: 1),
                          ListTile(
                            leading: Icon(Icons.category, color: accentTeal),
                            title: const Text('Brick Type'),
                            subtitle: Text(brickType),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Attendance
                    Text(
                      'Today\'s Attendance',
                      style: TextStyle(
                        color: accentTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      elevation: 1,
                      color: cardWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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

                    // Payment Summary
                    Text(
                      'Payment Summary',
                      style: TextStyle(
                        color: accentTeal,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      elevation: 1,
                      color: cardWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Per Lift Price only if not Staff
                          if (labour.occupation != 'Staff') ...[
                            ListTile(
                              leading: Icon(Icons.price_change, color: Colors.green),
                              title: const Text('Per Lift Price'),
                              subtitle: Text('Rs ${labour.perLiftPrice}'),
                            ),
                            Divider(height: 1),
                          ],
                          ListTile(
                            leading: Icon(Icons.today, color: lightBlue),
                            title: const Text("Today's Earnings"),
                            subtitle: Text(
                              labour.occupation != 'Staff'
                                ? 'Rs $todayEarnings  (Lifts: $todayLifts)'
                                : 'Rs $todayEarnings',
                            ),
                          ),
                          Divider(height: 1),
                          ListTile(
                            leading: Icon(Icons.calendar_today, color: accentTeal),
                            title: const Text('Monthly Earnings'),
                            subtitle: Text('Rs $monthlyEarnings'),
                          ),
                          Divider(height: 1),
                          ListTile(
                            leading: Icon(Icons.summarize, color: primaryBlue),
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
      ),
    );
  }
}