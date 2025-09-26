import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:lapabricks/pages/connection_page.dart';

class ConnectionGate extends StatelessWidget {
  final Widget child;
  const ConnectionGate({super.key, required this.child});

  Future<bool> hasInternet() async {
    // First, check if network is available
    final connectivityResult = await Connectivity().checkConnectivity();
    final isNetworkAvailable = connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi);

    if (!isNetworkAvailable) return false;

    // Now, try to ping a server for actual internet
    try {
      final response = await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: hasInternet(),
      builder: (context, initialSnapshot) {
        if (initialSnapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!initialSnapshot.data!) {
          return ConnectionPage(
            onRetry: () => (context as Element).markNeedsBuild(),
          );
        }
        return StreamBuilder<List<ConnectivityResult>>(
          stream: Connectivity().onConnectivityChanged,
          builder: (context, snapshot) {
            // When network changes, re-ping for real internet
            return FutureBuilder<bool>(
              future: hasInternet(),
              builder: (context, internetSnapshot) {
                if (internetSnapshot.connectionState != ConnectionState.done) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!internetSnapshot.data!) {
                  return ConnectionPage(
                    onRetry: () => (context as Element).markNeedsBuild(),
                  );
                }
                return child;
              },
            );
          },
        );
      },
    );
  }
}