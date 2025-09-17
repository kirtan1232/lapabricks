import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectivityGate extends StatefulWidget {
  final Widget child;
  const ConnectivityGate({super.key, required this.child});

  @override
  State<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<ConnectivityGate> {
  bool _offline = false;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _offline = (result == ConnectivityResult.none);
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_offline) {
      return Scaffold(
        body: Center(
          child: AlertDialog(
            title: const Text('No internet connection'),
            content: const Text('Please check your connection and try again.'),
            actions: [
              TextButton(
                child: const Text('Retry'),
                onPressed: _checkConnectivity,
              ),
              TextButton(
                child: const Text('Close'),
                onPressed: () {},
              ),
            ],
          ),
        ),
      );
    }
    return widget.child;
  }
}