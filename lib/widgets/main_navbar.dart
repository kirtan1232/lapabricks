import 'package:flutter/material.dart';

class MainNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final VoidCallback onQrTap;
  final bool navEnabled; // <-- New flag

  const MainNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onQrTap,
    this.navEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Modern color scheme matching the updated home page
    const Color primaryBlue = Color(0xFF2563EB);
    const Color lightGray = Color(0xFF64748B);
    const Color cardWhite = Color(0xFFFFFFFF);

    // Responsive sizing with overflow fix
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final iconSize = isTablet ? 30.0 : 26.0;
    final notchMargin = isTablet ? 10.0 : 6.0;
    final navBarHeight = isTablet ? 75.0 : 65.0;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: notchMargin,
        elevation: 0,
        color: cardWhite,
        height: navBarHeight,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 16,
          vertical: 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context: context,
              icon: Icons.home_rounded,
              label: 'Home',
              index: 0,
              isSelected: currentIndex == 0,
              primaryColor: primaryBlue,
              grayColor: lightGray,
              iconSize: iconSize,
              isTablet: isTablet,
              navEnabled: navEnabled,
            ),
            SizedBox(width: isTablet ? 50 : 35),
            _buildNavItem(
              context: context,
              icon: Icons.person_rounded,
              label: 'Profile',
              index: 2,
              isSelected: currentIndex == 2,
              primaryColor: primaryBlue,
              grayColor: lightGray,
              iconSize: iconSize,
              isTablet: isTablet,
              navEnabled: navEnabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    required Color primaryColor,
    required Color grayColor,
    required double iconSize,
    required bool isTablet,
    required bool navEnabled,
  }) {
    return GestureDetector(
      onTap: navEnabled ? () => onTap(index) : null,
      child: Opacity(
        opacity: navEnabled ? 1 : 0.4, // visually disable when not enabled
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 12,
            vertical: isTablet ? 8 : 6,
          ),
          decoration: BoxDecoration(
            color: isSelected && navEnabled
                ? primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? primaryColor : grayColor,
                size: iconSize,
              ),
              if (isTablet && isSelected) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? primaryColor : grayColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}