import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // LOGIC: Delete All Entries
  Future<void> _deleteAllEntries(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Everything?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("This will wipe all your mood notes permanently."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Delete All",
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Deleting..."),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      try {
        final moods = await ApiService.getMoods();
        for (var mood in moods) {
          await ApiService.deleteMood(mood['id']);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("All notes deleted."),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Failed to delete some notes."),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    }
  }

  // LOGIC: Delete Account
  Future<void> _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Account?",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
        ),
        content: const Text("This is permanent. All your data will be lost forever."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Delete Account",
              style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await ApiService.deleteUserAccount();
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (context.mounted) context.go('/');
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    }
  }

  // LOGIC: Logout
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) context.go('/');
  }

  Widget _buildSettingsCard({
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // FIX 1: Use .withValues(alpha: ...)
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    VoidCallback? onTap,
    bool showArrow = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          // FIX 2: Use .withValues(alpha: ...)
          color: (iconColor ?? const Color(0xFF8B5CF6)).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? const Color(0xFF8B5CF6),
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: titleColor ?? const Color(0xFF1F2937),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
            )
          : null,
      trailing: showArrow
          ? const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF9CA3AF),
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildSectionHeader(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
          color: color ?? const Color(0xFF6B7280),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // Account Section
          _buildSectionHeader("Account"),
          _buildSettingsCard(
            children: [
              _buildSettingsTile(
                icon: Icons.person_outline,
                title: "Edit Profile",
                subtitle: "Change name or email",
                onTap: () => context.push('/settings/profile'),
              ),
              const Divider(height: 1, indent: 72, endIndent: 20),
              _buildSettingsTile(
                icon: Icons.lock_outline,
                title: "Change Password",
                subtitle: "Update your password",
                onTap: () => context.push('/settings/password'),
              ),
            ],
          ),

          // Data Management Section
          _buildSectionHeader("Data Management"),
          _buildSettingsCard(
            children: [
              _buildSettingsTile(
                icon: Icons.delete_sweep_outlined,
                title: "Delete All Entries",
                subtitle: "Remove all mood notes",
                iconColor: const Color(0xFFF59E0B),
                showArrow: false,
                onTap: () => _deleteAllEntries(context),
              ),
            ],
          ),

          // Danger Zone Section
          _buildSectionHeader("Danger Zone", color: const Color(0xFFDC2626)),
          _buildSettingsCard(
            children: [
              _buildSettingsTile(
                icon: Icons.delete_forever_outlined,
                title: "Delete Account",
                subtitle: "Permanently delete your account",
                iconColor: const Color(0xFFDC2626),
                titleColor: const Color(0xFFDC2626),
                showArrow: false,
                onTap: () => _deleteAccount(context),
              ),
            ],
          ),

          // Logout Section
          const SizedBox(height: 16),
          _buildSettingsCard(
            children: [
              _buildSettingsTile(
                icon: Icons.logout_outlined,
                title: "Logout",
                subtitle: "Sign out of your account",
                iconColor: const Color(0xFF6B7280),
                showArrow: false,
                onTap: () => _logout(context),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}