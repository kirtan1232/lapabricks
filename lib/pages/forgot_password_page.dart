import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  bool loading = false;

  Future<void> _sendResetEmail() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Please enter your email', false);
      return;
    }
    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showMessage('Password reset email sent!', true);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showMessage('Email is not registered', false);
      } else if (e.code == 'invalid-email') {
        _showMessage('Invalid email address', false);
      } else {
        _showMessage('Failed to send reset email', false);
      }
    } catch (e) {
      _showMessage('Error: $e', false);
    }
    setState(() => loading = false);
  }

  void _showMessage(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  const Text(
                    'Enter your registered email address to receive a password reset link.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _sendResetEmail,
                    child: const Text('Send Reset Email'),
                  ),
                ],
              ),
      ),
    );
  }
}