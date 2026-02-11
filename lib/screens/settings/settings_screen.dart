import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tracely/core/providers/auth_provider.dart';
import 'package:tracely/core/providers/theme_mode_provider.dart';
import 'package:tracely/core/widgets/confirmation_dialog.dart';
import 'package:tracely/screens/logs/logs_screen.dart';
import 'package:tracely/services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  String _email = 'Loading...';
  String _accountId = '';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final data = await ApiService().getUserSettings();
      if (!mounted) return;
      setState(() {
        _email = data['email'] ?? 'user@example.com';
        _accountId = data['user_id'] ?? data['id'] ?? '';
        _notificationsEnabled = data['notifications_enabled'] ?? true;

        // Sync theme from server if present
        final serverTheme = data['theme'];
        if (serverTheme != null) {
          final provider =
              Provider.of<ThemeModeProvider>(context, listen: false);
          if (serverTheme == 'dark' && !provider.isDarkMode) {
            provider.setThemeMode(ThemeMode.dark);
          } else if (serverTheme == 'light' && provider.isDarkMode) {
            provider.setThemeMode(ThemeMode.light);
          }
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    try {
      await ApiService()
          .updateUserSettings({'notifications_enabled': value});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(title: Text('Settings')),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SettingsSection(
                title: 'Appearance',
                children: [
                  _SettingsTile(
                    icon: Icons.dark_mode_rounded,
                    title: 'Dark Mode',
                    trailing: Consumer<ThemeModeProvider>(
                      builder: (context, provider, _) => Switch(
                        value: provider.isDarkMode,
                        onChanged: (_) {
                          provider.toggleTheme();
                          // Sync to backend
                          ApiService().updateUserSettings({
                            'theme':
                                provider.isDarkMode ? 'dark' : 'light',
                          });
                        },
                      ),
                    ),
                    subtitle: 'Default: On',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SettingsSection(
                title: 'Notifications',
                children: [
                  _SettingsTile(
                    icon: Icons.notifications_rounded,
                    title: 'Push Notifications',
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: _saveNotifications,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SettingsSection(
                title: 'Account',
                children: [
                  _SettingsTile(
                    icon: Icons.person_rounded,
                    title: 'Email',
                    subtitle: _isLoading ? 'Loading...' : _email,
                  ),
                  if (_accountId.isNotEmpty)
                    _SettingsTile(
                      icon: Icons.badge_rounded,
                      title: 'Account ID',
                      subtitle: _accountId.length > 12
                          ? '${_accountId.substring(0, 12)}...'
                          : _accountId,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              _SettingsSection(
                title: 'Data',
                children: [
                  _SettingsTile(
                    icon: Icons.description_rounded,
                    title: 'View Logs',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const LogsScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SettingsSection(
                title: 'Actions',
                children: [
                  _SettingsTile(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    isDestructive: true,
                    onTap: () async {
                      final confirmed = await ConfirmationDialog.show(
                        context,
                        title: 'Logout',
                        message: 'Are you sure you want to logout?',
                        confirmText: 'Logout',
                        cancelText: 'Cancel',
                        isDestructive: true,
                      );
                      if (confirmed == true && context.mounted) {
                        await context.read<AuthProvider>().logout();
                      }
                    },
                  ),
                ],
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : null;

    return ListTile(
      leading: Icon(
        icon,
        color: color ?? theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
