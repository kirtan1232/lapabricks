import 'package:flutter/material.dart';
import 'main_navbar.dart';

class PageWithNavBar extends StatelessWidget {
  final int currentIndex;
  final Widget child;
  final void Function(int) onTap;

  const PageWithNavBar({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: MainNavBar(
        currentIndex: currentIndex,
        onTap: onTap,
      ),
    );
  }
}