import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapabricks/pages/app.dart';
import 'package:lapabricks/connection/connection_page.dart'; // <-- import this!
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LapaLoginPage extends StatefulWidget {
  const LapaLoginPage({super.key});
  @override
  State<LapaLoginPage> createState() => _LapaLoginPageState();
}

class _LapaLoginPageState extends State<LapaLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool passwordVisible = false;
  final _storage = const FlutterSecureStorage();

  bool _isLoggingIn = false; // <--- add this

  Future<void> login() async {
    if (_isLoggingIn) return; // Block multiple taps
    setState(() => _isLoggingIn = true);

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('Email and password are required', false);
      setState(() => _isLoggingIn = false);
      return;
    }

    try {
      await _actualLogin().timeout(
        const Duration(seconds: 8),
        onTimeout: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ConnectionPage(
              onRetry: () {
                Navigator.of(context).pop();
                login();
              },
            ),
          ));
          throw Exception('Timeout');
        },
      );
    } catch (e) {
      // Optionally handle error
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  Future<void> _actualLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Fetch user profile and role
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(credential.user!.uid)
        .get();
    final role = userDoc.data()?['role'] ?? 'user';

    showMessage('Login Successful!', true);

    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'password', value: password);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => App(userRole: role)),
      (route) => false,
    );
  }

  Future<void> loginWithFingerprint() async {
    final LocalAuthentication auth = LocalAuthentication();
    bool didAuthenticate = false;
    try {
      didAuthenticate = await auth.authenticate(
        localizedReason: 'Authenticate with fingerprint to login',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (e) {
      showMessage('Fingerprint not available in this device.', false);
      return;
    }
    if (didAuthenticate) {
      final email = await _storage.read(key: 'email');
      final password = await _storage.read(key: 'password');
      if (email != null && password != null) {
        try {
          await _fingerprintLogin(email, password).timeout(
            const Duration(seconds: 8),
            onTimeout: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ConnectionPage(
                  onRetry: () {
                    Navigator.of(context).pop();
                    loginWithFingerprint();
                  },
                ),
              ));
              throw Exception('Timeout');
            },
          );
        } on FirebaseAuthException catch (e) {
          showMessage('No Internet Connection', false);
          await _storage.delete(key: 'email');
          await _storage.delete(key: 'password');
        }
      } else {
        showMessage('No saved credentials. Please login manually.', false);
      }
    } else {
      showMessage('Fingerprint authentication failed.', false);
    }
  }

  Future<void> _fingerprintLogin(String email, String password) async {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Fetch user profile and role
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(credential.user!.uid)
        .get();
    final role = userDoc.data()?['role'] ?? 'user';

    showMessage('Fingerprint Login Successful!', true);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => App(userRole: role)),
      (route) => false,
    );
  }

  void showMessage(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        backgroundColor: success
            ? const Color(0xFF059669) // Modern green
            : const Color(0xFFDC2626), // Modern red
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> hasSavedCredentials() async {
    final email = await _storage.read(key: 'email');
    final password = await _storage.read(key: 'password');
    return email != null && password != null;
  }

  @override
  Widget build(BuildContext context) {
    // Modern color scheme matching home page
    const Color primaryBlue = Color(0xFF2563EB);
    const Color lightBlue = Color(0xFF3B82F6);
    const Color accentTeal = Color(0xFF06B6D4);
    const Color backgroundGray = Color(0xFFF8FAFC);
    const Color cardWhite = Color(0xFFFFFFFF);
    const Color darkGray = Color(0xFF1E293B);
    const Color lightGray = Color(0xFF64748B);

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;

    return Scaffold(
      backgroundColor: backgroundGray,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth < 500
              ? constraints.maxWidth * 0.95
              : constraints.maxWidth < 800
                  ? 450
                  : 650;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 16,
                vertical: isTablet ? 48 : 24,
              ),
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding: EdgeInsets.all(isTablet ? 40 : 28),
                decoration: BoxDecoration(
                  color: cardWhite,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo with enhanced styling
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryBlue.withOpacity(0.1),
                            accentTeal.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SizedBox(
                        height: isTablet ? 100 : 80,
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // Title with modern styling
                    Column(
                      children: [
                        Text(
                          'LAPA BRICKS',
                          style: TextStyle(
                            fontSize: isTablet ? 32 : 28,
                            fontWeight: FontWeight.w900,
                            color: primaryBlue,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.1),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 3,
                          width: 80,
                          margin: const EdgeInsets.only(top: 8, bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryBlue, accentTeal],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),

                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.w600,
                        color: darkGray,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please sign in to continue',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 15,
                        color: lightGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: isTablet ? 32 : 28),

                    // Email Input with modern design
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: emailController,
                        style: TextStyle(
                          fontSize: isTablet ? 17 : 16,
                          color: darkGray,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryBlue, lightBlue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.email_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          labelText: 'Email Address',
                          labelStyle: TextStyle(
                            color: lightGray,
                            fontWeight: FontWeight.w500,
                          ),
                          filled: true,
                          fillColor: backgroundGray,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryBlue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password Input with modern design
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: passwordController,
                        style: TextStyle(
                          fontSize: isTablet ? 17 : 16,
                          color: darkGray,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Container(
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryBlue, lightBlue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            color: lightGray,
                            fontWeight: FontWeight.w500,
                          ),
                          filled: true,
                          fillColor: backgroundGray,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryBlue, width: 2),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              passwordVisible
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                              color: lightGray,
                            ),
                            onPressed: () {
                              setState(() => passwordVisible = !passwordVisible);
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        obscureText: !passwordVisible,
                      ),
                    ),
                    SizedBox(height: isTablet ? 28 : 24),

                    // Login buttons with modern design
                    FutureBuilder(
                      future: hasSavedCredentials(),
                      builder: (context, snapshot) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Container(
                                height: isTablet ? 54 : 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primaryBlue, lightBlue],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryBlue.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _isLoggingIn ? null : login,
                                  child: _isLoggingIn
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: isTablet ? 18 : 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            // Only show fingerprint button if NOT web and credentials are saved
                            if (!kIsWeb &&
                                snapshot.connectionState == ConnectionState.done &&
                                snapshot.data == true) ...[
                              const SizedBox(width: 16),
                              Container(
                                width: isTablet ? 54 : 50,
                                height: isTablet ? 54 : 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [accentTeal, primaryBlue],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentTeal.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: loginWithFingerprint,
                                    child: Tooltip(
                                      message: 'Login with Fingerprint',
                                      child: Icon(
                                        Icons.fingerprint_rounded,
                                        size: isTablet ? 28 : 24,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}