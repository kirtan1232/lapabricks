import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:lapabricks/pages/connection_page.dart';

class ConnectionGate extends StatefulWidget {
  final Widget child;
  const ConnectionGate({super.key, required this.child});

  @override
  State<ConnectionGate> createState() => _ConnectionGateState();
}

class _ConnectionGateState extends State<ConnectionGate> {
  bool _checking = true;
  bool _hasInternet = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkInternet();
    // Listen for network changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((_) {
      _checkInternet();
    });
    // Also check every 5 seconds for real internet (even if network doesn't change)
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkInternet());
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkInternet() async {
    final isConnected = await _hasInternetFunc();
    if (!mounted) return;
    setState(() {
      _hasInternet = isConnected;
      _checking = false;
    });
  }

  Future<bool> _hasInternetFunc() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    final isNetworkAvailable = connectivityResults.contains(ConnectivityResult.mobile) ||
        connectivityResults.contains(ConnectivityResult.wifi);
    if (!isNetworkAvailable) return false;
    try {
      final response = await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_hasInternet) {
      return ConnectionPage(
        onRetry: () => _checkInternet(),
      );
    }
    return widget.child;
  }
}