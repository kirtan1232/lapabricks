import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_page.dart';
import 'app.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool passwordVisible = false;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Validation
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

  void showMessage(String msg, bool success) {
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
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
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
            ElevatedButton(onPressed: login, child: const Text('Login')),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}