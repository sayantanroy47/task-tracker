import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/notification_preferences.dart';
import '../../shared/providers/notification_providers.dart';
import '../../shared/providers/app_providers.dart';

/// Comprehensive notification settings screen
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync = ref.watch(notificationPreferencesProvider);
    final appState = ref.watch(appStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        elevation: 0,
      ),
      body: preferencesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load settings: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(notificationPreferencesProvider.notifier).resetToDefaults();
                },
                child: const Text('Reset to Defaults'),
              ),
            ],
          ),
        ),
        data: (preferences) => _buildSettingsContent(context, ref, preferences, appState),
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context, 
    WidgetRef ref, 
    NotificationPreferences preferences,
    AppState appState,
  ) {
    final hasPermissions = appState is AppStateReady ? appState.hasNotificationPermissions : false;
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Permission status
        if (!hasPermissions) ...[
          _buildPermissionWarning(context, ref),
          const SizedBox(height: 24),
        ],

        // Basic notification settings
        _buildBasicSettings(context, ref, preferences),
        const SizedBox(height: 24),

        // Reminder settings
        _buildReminderSettings(context, ref, preferences),
        const SizedBox(height: 24),

        // Quiet hours settings
        _buildQuietHoursSettings(context, ref, preferences),
        const SizedBox(height: 24),

        // Advanced settings
        _buildAdvancedSettings(context, ref, preferences),
        const SizedBox(height: 24),

        // Reset button
        _buildResetSection(context, ref),
      ],
    );
  }

  Widget _buildPermissionWarning(BuildContext context, WidgetRef ref) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.warning,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications Disabled',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Grant notification permission to receive task reminders.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                ref.read(appStateProvider.notifier).requestNotificationPermissions();
              },
              child: const Text('Enable'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicSettings(BuildContext context, WidgetRef ref, NotificationPreferences preferences) {
    return _SettingsSection(
      title: 'Basic Settings',
      children: [
        _SettingsListTile(
          leading: const Icon(Icons.notifications),
          title: 'Enable Notifications',
          subtitle: 'Receive reminders for your tasks',
          trailing: Switch(
            value: preferences.notificationsEnabled,
            onChanged: (value) {
              ref.read(notificationPreferencesProvider.notifier).setNotificationsEnabled(value);
            },
          ),
        ),
        _SettingsListTile(
          leading: const Icon(Icons.volume_up),
          title: 'Sound',
          subtitle: 'Play sound for notifications',
          trailing: Switch(
            value: preferences.soundEnabled,
            onChanged: preferences.notificationsEnabled ? (value) {
              ref.read(notificationPreferencesProvider.notifier).setSoundEnabled(value);
            } : null,
          ),
        ),
        _SettingsListTile(
          leading: const Icon(Icons.vibration),
          title: 'Vibration',
          subtitle: 'Vibrate for notifications',
          trailing: Switch(
            value: preferences.vibrationEnabled,
            onChanged: preferences.notificationsEnabled ? (value) {
              ref.read(notificationPreferencesProvider.notifier).setVibrationEnabled(value);
            } : null,
          ),
        ),
        _SettingsListTile(
          leading: const Icon(Icons.notifications_active),
          title: 'Badge',
          subtitle: 'Show badge count on app icon',
          trailing: Switch(
            value: preferences.badgeEnabled,
            onChanged: preferences.notificationsEnabled ? (value) {
              ref.read(notificationPreferencesProvider.notifier).setBadgeEnabled(value);
            } : null,
          ),
        ),
      ],
    );
  }

  Widget _buildReminderSettings(BuildContext context, WidgetRef ref, NotificationPreferences preferences) {
    return _SettingsSection(
      title: 'Default Reminders',
      children: [
        _SettingsListTile(
          leading: const Icon(Icons.schedule),
          title: 'Default Reminder Times',
          subtitle: _formatReminderIntervals(preferences.defaultReminderIntervals),
          trailing: const Icon(Icons.chevron_right),
          onTap: preferences.notificationsEnabled ? () {
            _showReminderIntervalsDialog(context, ref, preferences.defaultReminderIntervals);
          } : null,
        ),
        _SettingsListTile(
          leading: const Icon(Icons.priority_high),
          title: 'Notification Priority',
          subtitle: _formatPriority(preferences.priority),
          trailing: const Icon(Icons.chevron_right),
          onTap: preferences.notificationsEnabled ? () {
            _showPriorityDialog(context, ref, preferences.priority);
          } : null,
        ),
      ],
    );
  }

  Widget _buildQuietHoursSettings(BuildContext context, WidgetRef ref, NotificationPreferences preferences) {
    return _SettingsSection(
      title: 'Quiet Hours',
      children: [
        _SettingsListTile(
          leading: const Icon(Icons.bedtime),
          title: 'Enable Quiet Hours',
          subtitle: 'Reduce notifications during specified times',
          trailing: Switch(
            value: preferences.quietHoursEnabled,
            onChanged: preferences.notificationsEnabled ? (value) {
              ref.read(notificationPreferencesProvider.notifier).setQuietHours(
                enabled: value,
                startTime: preferences.quietHoursStart ?? const TimeOfDayQuiet(hour: 22, minute: 0),
                endTime: preferences.quietHoursEnd ?? const TimeOfDayQuiet(hour: 7, minute: 0),
              );
            } : null,
          ),
        ),
        if (preferences.quietHoursEnabled) ...[
          _SettingsListTile(
            leading: const Icon(Icons.access_time),
            title: 'Start Time',
            subtitle: preferences.quietHoursStart?.toDisplayString() ?? '10:00 PM',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showTimePickerDialog(
                context,
                ref,
                'Quiet Hours Start Time',
                preferences.quietHoursStart ?? const TimeOfDayQuiet(hour: 22, minute: 0),
                (time) {
                  ref.read(notificationPreferencesProvider.notifier).setQuietHours(
                    enabled: preferences.quietHoursEnabled,
                    startTime: time,
                    endTime: preferences.quietHoursEnd,
                  );
                },
              );
            },
          ),
          _SettingsListTile(
            leading: const Icon(Icons.access_time_filled),
            title: 'End Time',
            subtitle: preferences.quietHoursEnd?.toDisplayString() ?? '7:00 AM',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showTimePickerDialog(
                context,
                ref,
                'Quiet Hours End Time',
                preferences.quietHoursEnd ?? const TimeOfDayQuiet(hour: 7, minute: 0),
                (time) {
                  ref.read(notificationPreferencesProvider.notifier).setQuietHours(
                    enabled: preferences.quietHoursEnabled,
                    startTime: preferences.quietHoursStart,
                    endTime: time,
                  );
                },
              );
            },
          ),
          _SettingsListTile(
            leading: const Icon(Icons.warning),
            title: 'Allow Urgent Interruptions',
            subtitle: 'High-priority notifications can break quiet hours',
            trailing: Switch(
              value: preferences.allowInterruptions,
              onChanged: (value) {
                ref.read(notificationPreferencesProvider.notifier).setAllowInterruptions(value);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedSettings(BuildContext context, WidgetRef ref, NotificationPreferences preferences) {
    return _SettingsSection(
      title: 'Advanced',
      children: [
        _SettingsListTile(
          leading: const Icon(Icons.lock_open),
          title: 'Show on Lock Screen',
          subtitle: 'Display notifications when device is locked',
          trailing: Switch(
            value: preferences.showOnLockScreen,
            onChanged: preferences.notificationsEnabled ? (value) {
              ref.read(notificationPreferencesProvider.notifier).setShowOnLockScreen(value);
            } : null,
          ),
        ),
      ],
    );
  }

  Widget _buildResetSection(BuildContext context, WidgetRef ref) {
    return _SettingsSection(
      title: 'Reset',
      children: [
        _SettingsListTile(
          leading: Icon(
            Icons.restore,
            color: Theme.of(context).colorScheme.error,
          ),
          title: 'Reset to Defaults',
          subtitle: 'Restore all notification settings to default values',
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showResetConfirmationDialog(context, ref),
        ),
      ],
    );
  }

  String _formatReminderIntervals(List<ReminderInterval> intervals) {
    if (intervals.isEmpty) return 'None';
    return intervals.map((interval) => interval.displayName).join(', ');
  }

  String _formatPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.medium:
        return 'Medium';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }

  void _showReminderIntervalsDialog(BuildContext context, WidgetRef ref, List<ReminderInterval> currentIntervals) {
    showDialog(
      context: context,
      builder: (context) => _ReminderIntervalsDialog(
        currentIntervals: currentIntervals,
        onChanged: (intervals) {
          ref.read(notificationPreferencesProvider.notifier).setDefaultReminderIntervals(intervals);
        },
      ),
    );
  }

  void _showPriorityDialog(BuildContext context, WidgetRef ref, NotificationPriority currentPriority) {
    showDialog(
      context: context,
      builder: (context) => _PriorityDialog(
        currentPriority: currentPriority,
        onChanged: (priority) {
          ref.read(notificationPreferencesProvider.notifier).setPriority(priority);
        },
      ),
    );
  }

  void _showTimePickerDialog(
    BuildContext context,
    WidgetRef ref,
    String title,
    TimeOfDayQuiet currentTime,
    Function(TimeOfDayQuiet) onChanged,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentTime.hour, minute: currentTime.minute),
      helpText: title,
    );

    if (picked != null) {
      onChanged(TimeOfDayQuiet(hour: picked.hour, minute: picked.minute));
    }
  }

  void _showResetConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all notification settings to their default values? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(notificationPreferencesProvider.notifier).resetToDefaults();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
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

/// Dialog for selecting reminder intervals
class _ReminderIntervalsDialog extends StatefulWidget {
  final List<ReminderInterval> currentIntervals;
  final Function(List<ReminderInterval>) onChanged;

  const _ReminderIntervalsDialog({
    required this.currentIntervals,
    required this.onChanged,
  });

  @override
  State<_ReminderIntervalsDialog> createState() => _ReminderIntervalsDialogState();
}

class _ReminderIntervalsDialogState extends State<_ReminderIntervalsDialog> {
  late Set<ReminderInterval> selectedIntervals;

  @override
  void initState() {
    super.initState();
    selectedIntervals = Set.from(widget.currentIntervals);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Default Reminder Times'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ReminderInterval.values.map((interval) {
          return CheckboxListTile(
            title: Text(interval.displayName),
            value: selectedIntervals.contains(interval),
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  selectedIntervals.add(interval);
                } else {
                  selectedIntervals.remove(interval);
                }
              });
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            widget.onChanged(selectedIntervals.toList());
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Dialog for selecting notification priority
class _PriorityDialog extends StatelessWidget {
  final NotificationPriority currentPriority;
  final Function(NotificationPriority) onChanged;

  const _PriorityDialog({
    required this.currentPriority,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notification Priority'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: NotificationPriority.values.map((priority) {
          return RadioListTile<NotificationPriority>(
            title: Text(_formatPriority(priority)),
            subtitle: Text(_getPriorityDescription(priority)),
            value: priority,
            groupValue: currentPriority,
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
                Navigator.of(context).pop();
              }
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  String _formatPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.medium:
        return 'Medium';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }

  String _getPriorityDescription(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'Quiet notifications, minimal interruption';
      case NotificationPriority.medium:
        return 'Standard notification behavior';
      case NotificationPriority.high:
        return 'Important notifications with sound';
      case NotificationPriority.urgent:
        return 'Critical notifications, bypass quiet hours';
    }
  }
}