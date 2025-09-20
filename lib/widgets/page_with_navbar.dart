import 'package:flutter/material.dart';
import 'package:lapabricks/widgets/main_navbar.dart';

class PageWithNavBar extends StatelessWidget {
  final int currentIndex;
  final Widget child;
  final void Function(int) onTap;
  final VoidCallback onQrTap;
  final bool showFab;
  final bool navEnabled;

  const PageWithNavBar({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTap,
    required this.onQrTap,
    this.showFab = true,
    this.navEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2563EB);
    const Color accentTeal = Color(0xFF06B6D4);

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final fabSize = isTablet ? 58.0 : 52.0;
    final fabIconSize = isTablet ? 32.0 : 28.0;

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // Hide FAB if keyboard is open OR showFab is false
    final showQrFab = showFab && !isKeyboardOpen;

    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: MainNavBar(
        currentIndex: currentIndex,
        onTap: onTap,
        onQrTap: onQrTap,
        navEnabled: navEnabled,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: showQrFab
          ? Container(
              margin: EdgeInsets.only(
                bottom: bottomPadding > 0 ? 8 : 4,
              ),
              child: Container(
                width: fabSize,
                height: fabSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(fabSize / 2),
                  gradient: LinearGradient(
                    colors: [primaryBlue, accentTeal],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(fabSize / 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(fabSize / 2),
                    onTap: onQrTap,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(fabSize / 2),
                      ),
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        size: fabIconSize,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      resizeToAvoidBottomInset: true,
      extendBody: true,
    );
  }
}