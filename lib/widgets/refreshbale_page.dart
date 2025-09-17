import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class RefreshablePage extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  const RefreshablePage({super.key, required this.child, required this.onRefresh});

  @override
  State<RefreshablePage> createState() => _RefreshablePageState();
}

class _RefreshablePageState extends State<RefreshablePage> {
  bool _checkingConnection = false;

  Future<void> _checkAndRefresh() async {
    setState(() => _checkingConnection = true);
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() => _checkingConnection = false);

    if (connectivityResult == ConnectivityResult.none) {
      _showNoInternetDialog();
    } else {
      await widget.onRefresh();
    }
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No internet connection'),
        content: const Text('Please check your connection and try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkAndRefresh();
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If loading connection, show progress
    if (_checkingConnection) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _checkAndRefresh,
      child: widget.child,
    );
  }
}