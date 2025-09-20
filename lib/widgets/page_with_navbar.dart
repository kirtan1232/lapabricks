import 'package:flutter/material.dart';
import 'package:lapabricks/widgets/main_navbar.dart';

class PageWithNavBar extends StatelessWidget {
  final int currentIndex;
  final Widget child;
  final void Function(int) onTap;
  final VoidCallback onQrTap;

  const PageWithNavBar({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTap,
    required this.onQrTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: MainNavBar(
        currentIndex: currentIndex,
        onTap: onTap,
        onQrTap: onQrTap,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        heroTag: "main-fab", // Unique hero tag to avoid errors
        shape: const StadiumBorder(),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 6,
        tooltip: 'QR Scan',
        child: const Icon(Icons.qr_code_scanner, size: 32),
        onPressed: onQrTap,
      ),
    );
  }
}