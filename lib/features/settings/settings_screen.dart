import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/app_routes.dart';

/// Settings screen for app configuration
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Notifications section
          _SettingsSection(
            title: 'Notifications',
            children: [
              _SettingsListTile(
                leading: const Icon(Icons.notifications),
                title: 'Notification Settings',
                subtitle: 'Configure reminders, sounds, and quiet hours',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push(AppRoutes.notificationSettings);
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Voice settings section
          _SettingsSection(
            title: 'Voice Input',
            children: [
              _SettingsListTile(
                leading: const Icon(Icons.mic),
                title: 'Voice Recognition',
                subtitle: 'Enable voice input for creating tasks',
                trailing: Switch(
                  value: true, // TODO: Connect to settings provider
                  onChanged: (value) {
                    // TODO: Implement voice toggle
                  },
                ),
              ),
              _SettingsListTile(
                leading: const Icon(Icons.language),
                title: 'Voice Language',
                subtitle: 'English (US)',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement language picker
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Appearance section
          _SettingsSection(
            title: 'Appearance',
            children: [
              _SettingsListTile(
                leading: const Icon(Icons.palette),
                title: 'Theme',
                subtitle: 'System default',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement theme picker
                },
              ),
              _SettingsListTile(
                leading: const Icon(Icons.color_lens),
                title: 'Color Scheme',
                subtitle: 'Blue',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement color picker
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Data section
          _SettingsSection(
            title: 'Data',
            children: [
              _SettingsListTile(
                leading: const Icon(Icons.backup),
                title: 'Export Tasks',
                subtitle: 'Save your tasks to a file',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement export functionality
                },
              ),
              _SettingsListTile(
                leading: const Icon(Icons.restore),
                title: 'Import Tasks',
                subtitle: 'Load tasks from a file',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Implement import functionality
                },
              ),
              _SettingsListTile(
                leading: Icon(
                  Icons.delete_forever,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: 'Clear All Tasks',
                subtitle: 'Delete all completed tasks',
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showClearTasksDialog(context),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // About section
          _SettingsSection(
            title: 'About',
            children: [
              _SettingsListTile(
                leading: const Icon(Icons.info),
                title: 'App Version',
                subtitle: '1.0.0+1',
                onTap: null,
              ),
              _SettingsListTile(
                leading: const Icon(Icons.privacy_tip),
                title: 'Privacy Policy',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show privacy policy
                },
              ),
              _SettingsListTile(
                leading: const Icon(Icons.gavel),
                title: 'Terms of Service',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show terms of service
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showClearTasksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Tasks'),
          content: const Text(
            'Are you sure you want to delete all completed tasks? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implement clear tasks functionality
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Completed tasks cleared'),
                  ),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}

/// Settings section widget
class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// Settings list tile widget
class _SettingsListTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  
  const _SettingsListTile({
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
      enabled: onTap != null,
    );
  }
}