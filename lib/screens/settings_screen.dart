import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/download_provider.dart';
import 'profile_screen.dart';
import 'beta_screen.dart';
import '../app_config.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/mock_backend.dart';
import 'auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final profile = context.watch<ProfileProvider>();
    final downloads = context.watch<DownloadProvider>();
    final primary = Theme.of(context).primaryColor;
    final name = profile.displayName.isEmpty ? 'Player' : profile.displayName;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: primary,
              child: Text(
                name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            subtitle: Text(
              profile.identifier.isEmpty ? 'Edit profile' : profile.identifier,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ),
        const _SectionTitle('Appearance'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Theme'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Dark'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.settings_suggest_outlined),
                        label: Text('System'),
                      ),
                    ],
                    selected: {themeProvider.themeMode},
                    onSelectionChanged: (selection) =>
                        themeProvider.setTheme(selection.first),
                  ),
                ),
              ],
            ),
          ),
        ),
        const _SectionTitle('Storage'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.sd_storage_outlined),
                title: const Text('Installed games'),
                subtitle: Text(
                  '${downloads.downloadedGames.length} installed · ${formatSize(downloads.installedMb)} used',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined),
                title: const Text('Uninstall all games'),
                enabled: downloads.downloadedGames.isNotEmpty,
                onTap: () => _uninstallAll(context),
              ),
            ],
          ),
        ),
        const _SectionTitle('More'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.view_carousel_outlined),
                title: const Text('Beta features'),
                subtitle: const Text('Game carousel preview'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BetaScreen()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About NovaPlay'),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'NovaPlay',
                  applicationVersion: '1.0.0',
                  applicationIcon: Icon(
                    Icons.sports_esports,
                    color: primary,
                    size: 40,
                  ),
                  children: const [
                    Text(
                      'A game store app made with Flutter, Provider and a '
                      'Node.js / Express REST API with a MySQL database.',
                    ),
                  ],
                ),
              ),
              if (AppConfig.demoMode) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restart_alt, color: Colors.orange),
                  title: const Text('Reset demo data'),
                  subtitle: const Text('Restore sample data and log out'),
                  onTap: () => _resetDemo(context),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _uninstallAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uninstall all games?'),
        content: const Text(
          'Your games stay in your library and can be downloaded again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Uninstall all'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<DownloadProvider>().removeAll();
    }
  }

  Future<void> _resetDemo(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset demo data?'),
        content: const Text(
          'This removes accounts, purchases and game edits made in this browser.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await MockBackend.instance.reset();
    if (!context.mounted) return;
    context.read<CartProvider>().clearCart();
    context.read<DownloadProvider>().removeAll();
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
