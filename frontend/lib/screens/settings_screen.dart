import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // LOGIC: Delete All Entries
  // Since the backend doesn't have a "Delete All" endpoint, we fetch all and delete one by one.
  Future<void> _deleteAllEntries(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Everything?"),
        content: const Text("This will wipe all your mood notes permanently."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete All", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deleting...")));
      try {
        final moods = await ApiService.getMoods();
        for (var mood in moods) {
          await ApiService.deleteMood(mood['id']);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All notes deleted.")));
        }
      } catch (e) {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete some notes.")));
        }
      }
    }
  }

  // LOGIC: Delete Account
  Future<void> _deleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text("This is permanent. Goodbye!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete Account", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await ApiService.deleteUserAccount();
        // Clear storage and go to login
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (context.mounted) context.go('/');
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings"), automaticallyImplyLeading: false),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Account", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Edit Profile"),
            subtitle: const Text("Change name or email"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/settings/profile'),
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Change Password"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/settings/password'),
          ),
          
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Data Management", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.orange),
            title: const Text("Delete All Entries"),
            onTap: () => _deleteAllEntries(context),
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Danger Zone", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Delete Account"),
            onTap: () => _deleteAccount(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}