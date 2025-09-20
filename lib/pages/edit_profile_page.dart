import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final nameController = TextEditingController();
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  bool changingPassword = false;
  bool passwordVisible = false;
  bool loading = false;
  String? userEmail;
  String? photoURL;

  // App color scheme (matches homepage, settings, etc.)
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color accentTeal = Color(0xFF06B6D4);
  static const Color backgroundGray = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color darkGray = Color(0xFF1E293B);
  static const Color lightGray = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email;
        photoURL = user.photoURL;
      });
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final name = doc.data()?['name'] ?? '';
        nameController.text = name;
      }
    }
  }

  Future<void> _updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final name = nameController.text.trim();
    if (user == null) return;
    if (name.isEmpty) {
      _showMessage('Name cannot be empty', false);
      return;
    }
    setState(() => loading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'name': name});
      _showMessage('Name updated!', true);
    } catch (e) {
      _showMessage('Failed to update name', false);
    }
    setState(() => loading = false);
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    if (user == null) return;

    if (currentPassword.isEmpty || newPassword.isEmpty) {
      _showMessage('Fill both password fields', false);
      return;
    }
    setState(() => loading = true);
    try {
      final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      _showMessage('Password changed!', true);
      currentPasswordController.clear();
      newPasswordController.clear();
      setState(() => changingPassword = false);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _showMessage('Current password is incorrect', false);
      } else if (e.code == 'weak-password') {
        _showMessage('New password is too weak', false);
      } else {
        _showMessage('Current password is incorrect', false);
      }
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
      backgroundColor: backgroundGray,
      appBar: AppBar(
        backgroundColor: cardWhite,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        titleSpacing: 0,
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LAPA BRICKS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: primaryBlue,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.1),
                    ),
                  ],
                ),
              ),
              Container(
                height: 3,
                width: 60,
                margin: const EdgeInsets.only(top: 4),
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
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 430),
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  child: Column(
                    children: [
                      Card(
                        color: cardWhite,
                        elevation: 7,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: accentTeal.withOpacity(0.14),
                                backgroundImage: photoURL != null ? NetworkImage(photoURL!) : null,
                                child: photoURL == null
                                    ? Icon(Icons.person, size: 38, color: lightGray)
                                    : null,
                              ),
                              const SizedBox(height: 18),
                              Text(
                                userEmail ?? '',
                                style: TextStyle(
                                  color: lightGray,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Card(
                        color: cardWhite,
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.edit, color: primaryBlue),
                                  const SizedBox(width: 7),
                                  Text(
                                    'Edit Name',
                                    style: const TextStyle(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: nameController,
                                decoration: InputDecoration(
                                  labelText: 'Name',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  prefixIcon: const Icon(Icons.person_outline),
                                  labelStyle: const TextStyle(color: darkGray, fontWeight: FontWeight.w500),
                                  filled: true,
                                  fillColor: backgroundGray,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                                ),
                                style: const TextStyle(fontSize: 15, color: darkGray, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.save),
                                  label: const Text('Update Name'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                  ),
                                  onPressed: _updateProfile,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Card(
                        color: cardWhite,
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => setState(() => changingPassword = !changingPassword),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lock_outline, color: accentTeal),
                                    const SizedBox(width: 7),
                                    Text(
                                      'Change Password',
                                      style: const TextStyle(
                                        color: accentTeal,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                    const Spacer(),
                                    AnimatedRotation(
                                      turns: changingPassword ? 0.5 : 0,
                                      duration: const Duration(milliseconds: 250),
                                      child: Icon(
                                        Icons.arrow_drop_down,
                                        size: 32,
                                        color: lightGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                child: changingPassword
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Column(
                                          children: [
                                            TextField(
                                              controller: currentPasswordController,
                                              decoration: InputDecoration(
                                                labelText: 'Current Password',
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                prefixIcon: const Icon(Icons.lock),
                                                labelStyle: const TextStyle(color: darkGray, fontWeight: FontWeight.w500),
                                                filled: true,
                                                fillColor: backgroundGray,
                                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                                              ),
                                              style: const TextStyle(fontSize: 15, color: darkGray, fontWeight: FontWeight.w500),
                                              obscureText: !passwordVisible,
                                            ),
                                            const SizedBox(height: 12),
                                            TextField(
                                              controller: newPasswordController,
                                              decoration: InputDecoration(
                                                labelText: 'New Password',
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                prefixIcon: const Icon(Icons.lock_outline),
                                                labelStyle: const TextStyle(color: darkGray, fontWeight: FontWeight.w500),
                                                filled: true,
                                                fillColor: backgroundGray,
                                                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    passwordVisible ? Icons.visibility : Icons.visibility_off,
                                                    color: primaryBlue,
                                                  ),
                                                  onPressed: () => setState(() => passwordVisible = !passwordVisible),
                                                ),
                                              ),
                                              style: const TextStyle(fontSize: 15, color: darkGray, fontWeight: FontWeight.w500),
                                              obscureText: !passwordVisible,
                                            ),
                                            const SizedBox(height: 14),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                icon: const Icon(Icons.lock_reset),
                                                label: const Text('Change Password'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: accentTeal,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                                ),
                                                onPressed: _changePassword,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
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