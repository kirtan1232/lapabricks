import 'package:flutter/material.dart';
import 'package:lapabricks/pages/login_page.dart';
import 'package:lapabricks/providers/labour_store.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';



void main() {
  runApp(const LabourApp());
}

class LabourApp extends StatelessWidget {
  const LabourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Lapa Bricks',
            theme: ThemeData(
              colorSchemeSeed: Colors.indigo,
              useMaterial3: true,
              brightness: Brightness.light,
            ),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return ChangeNotifierProvider(
          create: (_) => LabourStore(),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Lapa Bricks',
            theme: ThemeData(
              colorSchemeSeed: Colors.indigo,
              useMaterial3: true,
              brightness: Brightness.light,
            ),
            home: const LapaLoginPage(), // <-- Use the prefix here
          ),
        );
      },
    );
  }

  Future<void> _initializeApp() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();
    await Hive.openBox('labours');
    await Firebase.initializeApp();
    await FirebaseAuth.instance.signOut(); // Force sign out every time app starts!
  }
}