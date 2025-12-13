import 'package:flutter/material.dart';

// Assuming you have a Screen enum or similar for navigation
// enum Screen { dashboard, community, profile, settings }

class BottomNav extends StatelessWidget {
  final String currentScreen;
  final Function(String) onNavigate;
  final String? userType;

  const BottomNav({
    super.key,
    required this.currentScreen,
    required this.onNavigate,
    this.userType,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_outlined, 'Home', 'dashboard'),
            _buildNavItem(Icons.people_outline, 'Community', 'community'),
            _buildNavItem(Icons.person_outline, 'Profile', 'profile'),
            _buildNavItem(Icons.settings_outlined, 'Settings', 'settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, String screenName) {
    final isActive = currentScreen == screenName;
    return InkWell(
      onTap: () => onNavigate(screenName),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? const Color(0xFF00B8A9) : Colors.grey),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF00B8A9) : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
