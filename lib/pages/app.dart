import 'package:flutter/material.dart';
import 'package:lapabricks/pages/home_page.dart';
import 'package:lapabricks/pages/attendance_scan.dart';
import 'package:lapabricks/pages/settings_page.dart';
import 'package:lapabricks/providers/labour_store.dart';
import 'package:lapabricks/widgets/connectivity_gate.dart';
import 'package:lapabricks/widgets/page_with_navbar.dart';
import 'package:lapabricks/widgets/refreshbale_page.dart';
import 'package:lapabricks/utils/auto_logout_wrapper.dart'; // Import the AutoLogoutWrapper
import 'package:provider/provider.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _selectedIndex = 0; // Home is left and default

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _refreshLabours(BuildContext ctx) async {
    final store = ctx.read<LabourStore>();
    await store.loadLaboursAsync();
  }

  void _onQrTap() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AttendanceScanPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_selectedIndex) {
      case 0:
        body = RefreshablePage(
          child: const HomePage(),
          onRefresh: () => _refreshLabours(context),
        );
        break;
      case 2:
        body = RefreshablePage(
          child: const SettingsPage(),
          onRefresh: () => _refreshLabours(context),
        );
        break;
      default:
        body = RefreshablePage(
          child: const HomePage(),
          onRefresh: () => _refreshLabours(context),
        );
    }
    return AutoLogoutWrapper( // Wrap the entire app content with AutoLogoutWrapper
      child: PageWithNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
        onQrTap: _onQrTap,
        child: ConnectivityGate(child: body),
      ),
    );
  }
}