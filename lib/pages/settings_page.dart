import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String userName = '';
  bool loading = true;
  final _storage = const FlutterSecureStorage();

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
        setState(() {
          userName = doc.data()?['name'] ?? '';
          loading = false;
        });
      } else {
        setState(() {
          userName = '';
          loading = false;
        });
      }
    } else {
      setState(() {
        userName = '';
        loading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Delete credentials for fingerprint login
    await _storage.delete(key: 'email');
    await _storage.delete(key: 'password');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await _logout(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _editProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    ).then((_) {
      // Reload name after editing
      _loadUserName();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? 'No email';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(userName.isEmpty ? 'No Name' : userName),
                    subtitle: const Text('Full Name'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: Text(userEmail),
                    subtitle: const Text('Email'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Edit Profile'),
                    onTap: () => _editProfile(context),
                  ),
                  const Divider(),
                  const SizedBox(height: 24),
                  Center(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      onPressed: () => _showLogoutConfirmation(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}