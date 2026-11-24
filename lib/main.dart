import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lapabricks/utils/connection_gate.dart';
import 'package:lapabricks/auth/login_page.dart';
import 'package:lapabricks/pages/home_page.dart';
import 'package:lapabricks/connection/connection_page.dart';
import 'package:lapabricks/providers/labour_store.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  runApp(const LabourApp());
}

class LabourApp extends StatelessWidget {
  const LabourApp({super.key});



  // Only use ConnectionGate for Android/iOS
  bool get useConnectionGate =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

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
            home: const Scaffold(body: Center(child: CircularProgressIndicator())),
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
            builder: (context, child) {
              if (useConnectionGate) {
                return ConnectionGate(child: child ?? const SizedBox());
              } else {
                return child ?? const SizedBox();
              }
            },
            initialRoute: '/',
            routes: {
              '/': (context) => LapaLoginPage(), // Initial route IS login
              '/home': (context) => HomePage(),
              '/connection': (context) => ConnectionPage(onRetry: () {}),
            },
          ),
        );
      },
    );
  }
}
