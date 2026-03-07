import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF47B25);
    const darkBg = Color(0xFF121212);

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        title: const Text(
          'Admin Settings',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingsTile(
            context,
            icon: Icons.person,
            title: 'Profile Settings',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile Settings: Coming Soon')),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.security,
            title: 'Security & Permissions',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Security Settings: Coming Soon')),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.notifications,
            title: 'Notification Preferences',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications Settings: Coming Soon')),
              );
            },
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: 'Logout',
            iconColor: Colors.redAccent,
            textColor: Colors.redAccent,
            onTap: () {
              // Usually handled with FirebaseAuth.instance.signOut();
              // For now, pop to root.
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFFF47B25),
    Color textColor = Colors.white,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        onTap: onTap,
      ),
    );
  }
}
