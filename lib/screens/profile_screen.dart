// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(theme),
            const SizedBox(height: AppTheme.spacing20),
            _buildMenuSection('Account', [
              {'icon': Icons.person, 'title': 'Edit Profile', 'subtitle': 'Update your information'},
              {'icon': Icons.notifications, 'title': 'Notifications', 'subtitle': 'Manage notifications'},
              {'icon': Icons.lock, 'title': 'Privacy', 'subtitle': 'Privacy settings'},
            ], theme),
            const SizedBox(height: AppTheme.spacing12),
            _buildMenuSection('Preferences', [
              {'icon': Icons.palette, 'title': 'Theme', 'subtitle': 'Light or Dark mode'},
              {'icon': Icons.language, 'title': 'Language', 'subtitle': 'English'},
              {'icon': Icons.sports_soccer, 'title': 'Favorite Leagues', 'subtitle': 'Manage your preferences'},
            ], theme),
            const SizedBox(height: AppTheme.spacing12),
            _buildMenuSection('Support', [
              {'icon': Icons.help_outline, 'title': 'Help & Support', 'subtitle': 'Get help'},
              {'icon': Icons.info_outline, 'title': 'About', 'subtitle': 'App version 1.0.0'},
              {'icon': Icons.description, 'title': 'Terms & Conditions', 'subtitle': 'Read our terms'},
            ], theme),
            const SizedBox(height: AppTheme.spacing20),
            _buildLogoutButton(theme),
            const SizedBox(height: AppTheme.spacing20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              'U',
              style: AppTheme.heading1.copyWith(
                color: AppTheme.primaryColor,
                fontSize: 40,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          const Text(
            'User Name',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          const Text(
            'user@example.com',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('24', 'Predictions', Colors.white),
              Container(
                height: 40,
                width: 1,
                color: Colors.white30,
              ),
              _buildStatItem('68%', 'Accuracy', Colors.white),
              Container(
                height: 40,
                width: 1,
                color: Colors.white30,
              ),
              _buildStatItem('16', 'Won', Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(String title, List<Map<String, dynamic>> items, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
          child: Text(
            title,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;
              
              return Column(
                children: [
                  ListTile(
                    leading: Icon(
                      item['icon'] as IconData,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      item['title'] as String,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      item['subtitle'] as String,
                      style: AppTheme.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      // TODO: Handle navigation
                    },
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 72,
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            // TODO: Handle logout
          },
          icon: const Icon(Icons.logout, color: AppTheme.dangerColor),
          label: const Text(
            'Logout',
            style: TextStyle(
              color: AppTheme.dangerColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            side: const BorderSide(color: AppTheme.dangerColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        ),
      ),
    );
  }
}