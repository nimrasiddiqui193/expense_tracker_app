import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Log out?'),
            content: const Text(
              'Are you sure you want to log out of your account?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Log out'),
              ),
            ],
          ),
    );

    if (shouldLogout != true || !context.mounted) return;

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log out. Please try again.')),
      );
    }
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeMode mode,
    required ThemeMode selectedMode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final selected = selectedMode == mode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:
            selected
                ? theme.colorScheme.primary.withValues(alpha: 0.09)
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.65)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
          width: selected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(
              alpha: selected ? 0.08 : 0.025,
            ),
            blurRadius: selected ? 10 : 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: RadioListTile<ThemeMode>(
        value: mode,
        groupValue: selectedMode,
        onChanged: (value) {
          if (value != null) {
            ThemeController.setMode(value);
          }
        },
        secondary: Icon(
          icon,
          color:
              selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(subtitle),
        activeColor: theme.colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final displayName = user?.displayName?.trim();

    final name =
        displayName != null && displayName.isNotEmpty ? displayName : 'User';

    final email = user?.email ?? 'No email available';

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.20),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 46,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_rounded,
                  size: 50,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            name,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Account Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: const Text('Full Name'),
                  subtitle: Text(name),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email Address'),
                  subtitle: Text(email),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          Text(
            'Appearance',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose how Expense Tracker looks on your device.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),

          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.mode,
            builder: (context, selectedMode, child) {
              return Column(
                children: [
                  _buildThemeOption(
                    context: context,
                    mode: ThemeMode.system,
                    selectedMode: selectedMode,
                    icon: Icons.settings_suggest_rounded,
                    title: 'System default',
                    subtitle: 'Follow your device settings',
                  ),
                  _buildThemeOption(
                    context: context,
                    mode: ThemeMode.light,
                    selectedMode: selectedMode,
                    icon: Icons.light_mode_rounded,
                    title: 'Light mode',
                    subtitle: 'A clean, bright appearance',
                  ),
                  _buildThemeOption(
                    context: context,
                    mode: ThemeMode.dark,
                    selectedMode: selectedMode,
                    icon: Icons.dark_mode_rounded,
                    title: 'Dark mode',
                    subtitle: 'Comfortable in low light',
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
