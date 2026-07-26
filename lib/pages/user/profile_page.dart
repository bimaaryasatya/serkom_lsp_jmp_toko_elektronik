import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? '',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Nama'),
                    subtitle: Text(user?.name ?? ''),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: Text(user?.email ?? ''),
                  ),
                  const Divider(height: 1),
                  // Dark Mode Switcher Tersimpan di SharedPreferences
                  SwitchListTile(
                    secondary: Icon(
                      themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Mode Gelap (Dark Mode)'),
                    subtitle: const Text('Tersimpan di SharedPreferences'),
                    value: themeProvider.isDarkMode,
                    onChanged: (bool value) {
                      context.read<ThemeProvider>().toggleTheme(value);
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Keluar',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
