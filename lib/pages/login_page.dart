import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lapabricks/pages/app.dart';
import 'package:lapabricks/pages/forgot_password_page.dart';
import 'package:lapabricks/pages/register_page.dart';
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

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('Email and password are required', false);
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      showMessage('Login Successful!', true);

      await _storage.write(key: 'email', value: email);
      await _storage.write(key: 'password', value: password);

      // Navigation fix: Remove all previous pages
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const App()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        showMessage('Email not registered', false);
      } else if (e.code == 'wrong-password') {
        showMessage('Incorrect password', false);
      } else if (e.code == 'invalid-email') {
        showMessage('Invalid email address', false);
      } else {
        showMessage('Login failed. Please try again.', false);
      }
    } catch (e) {
      showMessage('Login failed. Please try again.', false);
    }
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
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          showMessage('Fingerprint Login Successful!', true);
          // Navigation fix: Remove all previous pages
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const App()),
            (route) => false,
          );
        } on FirebaseAuthException catch (e) {
          showMessage('Password changed. Please login with credentials.', false);
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

    // Responsive sizing
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
                                  onPressed: login,
                                  child: Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: isTablet ? 18 : 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (snapshot.connectionState == ConnectionState.done &&
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
                    SizedBox(height: isTablet ? 32 : 28),

                    // Modern divider
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  lightGray.withOpacity(0.3),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: lightGray,
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 16 : 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  lightGray.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 24 : 20),

                    // Create Account button
                    _buildActionButton(
                      icon: Icons.person_add_rounded,
                      label: 'Create Account',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      ),
                      primaryColor: primaryBlue,
                      isTablet: isTablet,
                    ),
                    SizedBox(height: 12),

                    // Forgot Password button just below Create Account
                    _buildActionButton(
                      icon: Icons.lock_reset_rounded,
                      label: 'Forgot Password?',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                      ),
                      primaryColor: accentTeal,
                      isTablet: isTablet,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color primaryColor,
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 12,
              vertical: isTablet ? 12 : 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: primaryColor,
                  size: isTablet ? 20 : 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 15 : 13,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}