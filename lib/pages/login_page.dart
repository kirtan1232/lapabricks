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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const App()),
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const App()),
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
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
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
    const Color cream = Color(0xFFFFF6E5);
    const Color lightOrange = Color(0xFFFFB74D);
    const Color orangeAccent = Color(0xFFFF9800);

    return Scaffold(
      backgroundColor: cream,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double maxWidth = constraints.maxWidth < 500
              ? constraints.maxWidth * 0.98
              : constraints.maxWidth < 800
                  ? 430
                  : 600;

          return Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: lightOrange.withOpacity(0.13),
                      blurRadius: 20,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: SizedBox(
                        height: 90,
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Text(
                      'Welcome to LapaBricks',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: orangeAccent,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Please login to continue',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                    ),
                    const SizedBox(height: 24),
                    // Email Input
                    TextField(
                      controller: emailController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email, color: orangeAccent),
                        labelText: 'Email',
                        filled: true,
                        fillColor: cream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: orangeAccent, width: 1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Password Input
                    TextField(
                      controller: passwordController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock, color: orangeAccent),
                        labelText: 'Password',
                        filled: true,
                        fillColor: cream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: orangeAccent, width: 1),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            passwordVisible ? Icons.visibility : Icons.visibility_off,
                            color: orangeAccent,
                          ),
                          onPressed: () {
                            setState(() => passwordVisible = !passwordVisible);
                          },
                        ),
                      ),
                      obscureText: !passwordVisible,
                    ),
                    const SizedBox(height: 18),
                    FutureBuilder(
                      future: hasSavedCredentials(),
                      builder: (context, snapshot) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 40,
                              width: 120,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: lightOrange,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: login,
                                child: const Text(
                                  'Login',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            (snapshot.connectionState == ConnectionState.done &&
                                    snapshot.data == true)
                                ? Tooltip(
                                    message: 'Login with Fingerprint',
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.fingerprint,
                                        size: 32,
                                        color: orangeAccent,
                                      ),
                                      onPressed: loginWithFingerprint,
                                    ),
                                  )
                                : const SizedBox(width: 32),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // Divider with text
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.orange[200],
                            thickness: 1.2,
                            endIndent: 10,
                          ),
                        ),
                        Text(
                          'or',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.orange[200],
                            thickness: 1.2,
                            indent: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Register and Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: TextButton.icon(
                            icon: const Icon(Icons.person_add, color: orangeAccent),
                            label: const Text('Create Account'),
                            style: TextButton.styleFrom(
                              foregroundColor: orangeAccent,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterPage()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: TextButton.icon(
                            icon: const Icon(Icons.lock_reset, color: orangeAccent),
                            label: const Text('Forgot Password?'),
                            style: TextButton.styleFrom(
                              foregroundColor: orangeAccent,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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