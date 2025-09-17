import 'package:flutter/material.dart';
import 'package:lapabricks/pages/settings_page.dart';
import 'home_page.dart';
import 'payment_page.dart';
import '../widgets/page_with_navbar.dart';
import '../widgets/refreshbale_page.dart';
import '../widgets/connectivity_gate.dart';
import 'package:provider/provider.dart';
import '../providers/labour_store.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _selectedIndex = 1; // Home in center

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _refreshLabours(BuildContext ctx) async {
    final store = ctx.read<LabourStore>();
    await store.loadLaboursAsync();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_selectedIndex) {
      case 0:
        body = RefreshablePage(
          child: const PaymentPage(),
          onRefresh: () => _refreshLabours(context),
        );
        break;
      case 1:
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
    // Wrap all pages in ConnectivityGate so if offline, the user is blocked
    return PageWithNavBar(
      currentIndex: _selectedIndex,
      onTap: _onNavTap,
      child: ConnectivityGate(child: body),
    );
  }
}