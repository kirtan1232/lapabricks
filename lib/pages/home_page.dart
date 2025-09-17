import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/labour_store.dart';
import 'add_labour_page.dart';
import 'labour_detail_page.dart';
import 'scan_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LabourStore>();
    if (!store.loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final labours = store.labours;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lapa Bricks'),
        actions: [
          IconButton(
            tooltip: 'Scan QR',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ScanPage()),
            ),
          ),
        ],
      ),
      body: labours.isEmpty
          ? const Center(child: Text('No labours yet. Tap + to add.'))
          : ListView.separated(
              itemCount: labours.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final labour = labours[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(labour.name.isEmpty ? '?' : labour.name[0].toUpperCase())),
                  title: Text(labour.name),
                  subtitle: Text('Attendance: ${labour.attendance.length}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LabourDetailPage(labourId: labour.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddLabourPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}