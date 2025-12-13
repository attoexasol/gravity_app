import 'package:flutter/material.dart';
import '../../../app/theme/app_text_styles.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          _buildProfileHeader(),
          const SizedBox(height: 24),

          // Stats Cards
          _buildStatsRow(),
          const SizedBox(height: 24),

          // Profile Options
          _buildProfileOption(
            icon: Icons.person_outline,
            title: 'Personal Information',
            subtitle: 'Update your profile details',
            onTap: () {},
          ),
          _buildProfileOption(
            icon: Icons.fitness_center_outlined,
            title: 'Fitness Goals',
            subtitle: 'Manage your wellness targets',
            onTap: () {},
          ),
          _buildProfileOption(
            icon: Icons.history,
            title: 'Activity History',
            subtitle: 'View your past activities',
            onTap: () {},
          ),
          _buildProfileOption(
            icon: Icons.emoji_events_outlined,
            title: 'Achievements',
            subtitle: 'Your wellness milestones',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00B8A9), Color(0xFF0A2342)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.person,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 20),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sarah Johnson',
                  style: ResponsiveTextStyles.textXl.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Member since Nov 2025',
                  style: ResponsiveTextStyles.textSm.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Customer',
                    style: ResponsiveTextStyles.textXs.copyWith(
                      color: const Color(0xFF0A2342),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department,
            value: '128',
            label: 'Streak Days',
            color: const Color(0xFFF9A71F),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.emoji_events,
            value: '24',
            label: 'Achievements',
            color: const Color(0xFFD4AF37),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: ResponsiveTextStyles.text2Xl.copyWith(
              color: const Color(0xFF0A2342),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: ResponsiveTextStyles.textSm.copyWith(
              color: const Color(0xFF0A2342).withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B8A9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF00B8A9),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: ResponsiveTextStyles.textBase.copyWith(
                          color: const Color(0xFF0A2342),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: ResponsiveTextStyles.textSm.copyWith(
                          color: const Color(0xFF0A2342).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF0A2342).withOpacity(0.3),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}