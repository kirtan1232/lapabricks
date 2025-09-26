import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lapabricks/pages/login_page.dart';

class AutoLogoutWrapper extends StatefulWidget {
  final Widget child;

  const AutoLogoutWrapper({super.key, required this.child});

  @override
  State<AutoLogoutWrapper> createState() => _AutoLogoutWrapperState();
}

class _AutoLogoutWrapperState extends State<AutoLogoutWrapper> with WidgetsBindingObserver {
  Timer? _idleTimer;
  DateTime? _pausedTime;
  final Duration _timeout = const Duration(minutes: 2);
  final _storage = const FlutterSecureStorage();
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLoginStatus();
  }

  void _checkLoginStatus() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _isLoggedIn = user != null;
    });
    if (_isLoggedIn) {
      _startIdleTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    super.dispose();
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_timeout, _performLogout);
  }

  void _resetIdleTimer() {
    if (_isLoggedIn) {
      _startIdleTimer();
    }
  }

  Future<void> _performLogout() async {
    if (!_isLoggedIn) return;

    await FirebaseAuth.instance.signOut();
    // Do not delete credentials to preserve fingerprint login
    // await _storage.delete(key: 'email');
    // await _storage.delete(key: 'password');

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LapaLoginPage()),
        (route) => false,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!_isLoggedIn) return;

    if (state == AppLifecycleState.paused) {
      _idleTimer?.cancel();
      _pausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedTime != null) {
        final durationInBackground = DateTime.now().difference(_pausedTime!);
        if (durationInBackground > _timeout) {
          _performLogout();
        } else {
          _startIdleTimer();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return widget.child;
    }

    return Listener(
      onPointerDown: (_) => _resetIdleTimer(),
      onPointerMove: (_) => _resetIdleTimer(),
      onPointerUp: (_) => _resetIdleTimer(),
      child: widget.child,
    );
  }
}