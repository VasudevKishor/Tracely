import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tracely/core/providers/theme_mode_provider.dart';
import 'package:tracely/core/widgets/confirmation_dialog.dart';
import 'package:tracely/screens/auth/login_screen.dart';
import 'package:tracely/screens/logs/logs_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                        onChanged: (_) => provider.toggleTheme(),
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
                      value: true,
                      onChanged: (_) {},
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
                    subtitle: 'user@example.com',
                  ),
                  _SettingsTile(
                    icon: Icons.badge_rounded,
                    title: 'Account ID',
                    subtitle: 'acc_xxxxxxxx',
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
                      MaterialPageRoute(builder: (_) => const LogsScreen()),
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
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (_) => false,
                        );
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
