import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/labour_store.dart';
import '../models/labour.dart';
import 'scan_page.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  void _scan(BuildContext context, String type) async {
    // Pass mode and type to ScanPage
    final labourId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => ScanPage(mode: "payment", paymentType: type)),
    );
    if (labourId == null) return;

    final store = context.read<LabourStore>();
    final labour = store.byId(labourId);
    if (labour == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found')),
      );
      return;
    }

    int amount = type == 'heavy' ? 50 : 30;
    final total = labour.heavyPayments + labour.lowPayments;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${labour.name} received Rs $amount. Total: Rs $total')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: () => _scan(context, 'heavy'),
              child: const Text('Heavy (Rs 50)'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _scan(context, 'low'),
              child: const Text('Low (Rs 30)'),
            ),
          ],
        ),
      ),
    );
  }
}