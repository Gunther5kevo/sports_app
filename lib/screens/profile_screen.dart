// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import 'auth/auth_wrapper.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await _authService.getUserData();
    setState(() {
      _userData = data;
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
          child: const Text('Logout'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    try {
      await _authService.signOut();
      
      // Navigate back to AuthWrapper which will show SignInScreen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.bgColor(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = _authService.currentUser;
    final userName = _userData?['name'] ?? user?.displayName ?? 'User';
    final userEmail = _userData?['email'] ?? user?.email ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, userName, userEmail),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Settings'),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    context,
                    Icons.person_outline,
                    'Edit Profile',
                    'Update your information',
                    onTap: () {
                      // Navigate to edit profile screen
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.notifications_none,
                    'Notifications',
                    'Manage alerts',
                    onTap: () {
                      // Navigate to notifications settings
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Preferences'),
                  const SizedBox(height: 12),
                  _buildThemeToggle(context),
                  _buildMenuItem(
                    context,
                    Icons.language,
                    'Language',
                    'English',
                    onTap: () {
                      // Navigate to language settings
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(context, 'Support'),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    context,
                    Icons.help_outline,
                    'Help & Support',
                    'Get help',
                    onTap: () {
                      // Navigate to help screen
                    },
                  ),
                  _buildMenuItem(
                    context,
                    Icons.info_outline,
                    'About',
                    'Version 1.0.0',
                    onTap: () {
                      // Show about dialog
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildLogoutButton(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String name, String email) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: ListTile(
        leading: Icon(
          isDark ? Icons.dark_mode : Icons.light_mode,
          color: AppTheme.primaryColor,
        ),
        title: Text(
          'Theme',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary(context),
          ),
        ),
        subtitle: Text(
          isDark ? 'Dark mode' : 'Light mode',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary(context),
          ),
        ),
        trailing: Switch(
          value: isDark,
          onChanged: (_) => themeProvider.toggleTheme(),
          activeColor: AppTheme.primaryColor,
        ),
        onTap: () => themeProvider.toggleTheme(),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary(context),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary(context),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppTheme.textSecondary(context),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Logout'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.dangerColor,
          side: const BorderSide(color: AppTheme.dangerColor),
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary(context),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
