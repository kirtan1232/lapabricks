import 'package:flutter/material.dart';

class MainNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final VoidCallback onQrTap;
  const MainNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onQrTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 15,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.home,
              color: currentIndex == 0 ? Colors.indigo : Colors.grey,
              size: 28,
            ),
            tooltip: 'Home',
            onPressed: () => onTap(0),
          ),
          const SizedBox(width: 40), // Spacer for QR notch
          IconButton(
            icon: Icon(
              Icons.person,
              color: currentIndex == 2 ? Colors.indigo : Colors.grey,
              size: 28,
            ),
            tooltip: 'Profile',
            onPressed: () => onTap(2),
          ),
        ],
      ),
    );
  }
}