import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'app.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool passwordVisible = false;

  // Secure storage instance
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

      // Store credentials securely for fingerprint login
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
          // If password changed or credentials invalid, force manual login
          showMessage(
            'Password changed. Please login with credentials.',
            false,
          );
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
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    passwordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => passwordVisible = !passwordVisible);
                  },
                ),
              ),
              obscureText: !passwordVisible,
            ),
            const SizedBox(height: 16),
            FutureBuilder(
              future: hasSavedCredentials(),
              builder: (context, snapshot) {
                return Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 40,
                        width: 120,
                        child: ElevatedButton(
                          onPressed: login,
                          child: const Text(
                            'Login',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      (snapshot.connectionState == ConnectionState.done &&
                              snapshot.data == true)
                          ? IconButton(
                              icon: const Icon(
                                Icons.fingerprint,
                                size: 32,
                                color: Colors.blueAccent,
                              ),
                              tooltip: 'Login with Fingerprint',
                              onPressed: loginWithFingerprint,
                            )
                          : const SizedBox(width: 32),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterPage()),
              ),
              child: const Text('Create Account'),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
              ),
              child: const Text('Forgot Password?'),
            ),
          ],
        ),
      ),
    );
  }
}
