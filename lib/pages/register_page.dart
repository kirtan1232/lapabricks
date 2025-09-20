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
          // Navigation fix: Remove previous pages
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LapaLoginPage()),
            (route) => false,
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

  @override
  Widget build(BuildContext context) {
    // Modern color scheme matching login page
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
                      'Create Your Account',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.w600,
                        color: darkGray,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fill your details to register',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 15,
                        color: lightGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: isTablet ? 32 : 28),
                    // Name Input
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
                        controller: nameController,
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
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          labelText: 'Name',
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
                    const SizedBox(height: 16),
                    // Email Input
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
                          labelText: 'Email',
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
                    const SizedBox(height: 16),
                    // Phone Input
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
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
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
                              Icons.phone_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          labelText: 'Phone Number',
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
                    const SizedBox(height: 16),
                    // Password Input
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
                    SizedBox(height: isTablet ? 32 : 28),
                    // Register button with modern design
                    SizedBox(
                      width: double.infinity,
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
                          onPressed: register,
                          child: Text(
                            'Register',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                    SizedBox(height: isTablet ? 20 : 15),
                    // Link to Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: TextButton.icon(
                            icon: Icon(Icons.login_rounded, color: primaryBlue),
                            label: const Text('Already have an account? Login'),
                            style: TextButton.styleFrom(
                              foregroundColor: primaryBlue,
                            ),
                            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LapaLoginPage()),
                              (route) => false,
                            ),
                          ),
                        ),
                      ],
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