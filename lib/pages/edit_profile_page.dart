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

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
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
      // Update Firestore name
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
      // Re-authenticate
      final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      _showMessage('Password changed!', true);
      currentPasswordController.clear();
      newPasswordController.clear();
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
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  const Text('Edit Name', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _updateProfile,
                    child: const Text('Update Name'),
                  ),
                  const Divider(height: 32),
                  ListTile(
                    title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: IconButton(
                      icon: Icon(changingPassword ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                      onPressed: () => setState(() => changingPassword = !changingPassword),
                    ),
                  ),
                  if (changingPassword)
                    Column(
                      children: [
                        TextField(
                          controller: currentPasswordController,
                          decoration: const InputDecoration(labelText: 'Current Password'),
                          obscureText: !passwordVisible,
                        ),
                        TextField(
                          controller: newPasswordController,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            suffixIcon: IconButton(
                              icon: Icon(passwordVisible ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => passwordVisible = !passwordVisible),
                            ),
                          ),
                          obscureText: !passwordVisible,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _changePassword,
                          child: const Text('Change Password'),
                        ),
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}