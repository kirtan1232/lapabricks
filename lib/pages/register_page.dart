import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lapabricks/pages/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  bool passwordVisible = false;

  Future<void> register() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    // Validation
    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      showMessage('All fields are required', false);
      return;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      showMessage('Phone number should be 10 digits', false);
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseAuth.instance.signOut();

      showMessage('Account created successfully!', true);

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LapaLoginPage()),
          );
        }
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        showMessage('Email already registered', false);
      } else if (e.code == 'invalid-email') {
        showMessage('Invalid email address', false);
      } else if (e.code == 'weak-password') {
        showMessage('Password should be at least 6 characters', false);
      } else {
        showMessage('Registration failed: ${e.message}', false);
      }
    } catch (e) {
      showMessage('Registration failed: $e', false);
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
                      'Create Your Account',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: orangeAccent,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Fill your details to register',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                    ),
                    const SizedBox(height: 24),
                    // Name Input
                    TextField(
                      controller: nameController,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person, color: orangeAccent),
                        labelText: 'Name',
                        filled: true,
                        fillColor: cream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: orangeAccent, width: 1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    // Phone Input
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.phone, color: orangeAccent),
                        labelText: 'Phone Number',
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
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: lightOrange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: register,
                        child: const Text(
                          'Register',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
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
                    // Link to Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: TextButton.icon(
                            icon: const Icon(Icons.login, color: orangeAccent),
                            label: const Text('Already have an account? Login'),
                            style: TextButton.styleFrom(
                              foregroundColor: orangeAccent,
                            ),
                            onPressed: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const LapaLoginPage()),
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