import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lapabricks/pages/edit_profile_page.dart';
import 'package:lapabricks/pages/login_page.dart';

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
    await _storage.delete(key: 'email');
    await _storage.delete(key: 'password');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LapaLoginPage()),
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
      _loadUserName();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? 'No email';

    const Color orangeAccent = Color(0xFFFF9800);
    const Color cream = Color(0xFFFFF6E5);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: orangeAccent,
        title: const Text('Settings'),
        elevation: 2,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    color: Colors.white,
                    elevation: 7,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: orangeAccent.withOpacity(0.15),
                            child: Text(
                              (userName.isNotEmpty ? userName[0].toUpperCase() : '?'),
                              style: TextStyle(
                                fontSize: 38,
                                color: orangeAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            userName.isEmpty ? 'No Name' : userName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: orangeAccent,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            userEmail,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Divider(thickness: 1.2, color: orangeAccent.withOpacity(0.13)),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orangeAccent,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit Profile', style: TextStyle(fontSize: 16)),
                              onPressed: () => _editProfile(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              icon: const Icon(Icons.logout),
                              label: const Text('Logout', style: TextStyle(fontSize: 16)),
                              onPressed: () => _showLogoutConfirmation(context),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}