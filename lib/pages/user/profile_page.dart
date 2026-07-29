import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void _showEditProfileDialog() {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surface,
          title: const Text('Edit Profil ✏️'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final response = await http.put(
                    Uri.parse('${AppConstants.apiBaseUrl}/users/${user.id}'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({'name': nameController.text.trim(), 'email': emailController.text.trim()}),
                  );
                  if (response.statusCode == 200 && mounted) {
                    auth.login(emailController.text.trim(), user.password);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profil berhasil diperbarui')),
                    );
                  }
                } catch (_) {}
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final oldPwController = TextEditingController();
    final newPwController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surface,
          title: const Text('Ganti Password 🔑'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPwController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password Lama'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPwController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password Baru'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final response = await http.put(
                    Uri.parse('${AppConstants.apiBaseUrl}/users/${user.id}/password'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({
                      'oldPassword': oldPwController.text,
                      'newPassword': newPwController.text,
                    }),
                  );
                  final data = json.decode(response.body);
                  if (data['success'] == true && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password berhasil diubah')),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(data['message'] ?? 'Gagal ubah password'), backgroundColor: cs.error),
                    );
                  }
                } catch (_) {}
              },
              child: const Text('Simpan Password'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.user;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _showEditProfileDialog),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [cs.primary, cs.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: cs.surface,
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: cs.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(user?.name ?? '', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: user?.role == 'admin'
                    ? (isDark ? const Color(0xFF2D1854) : const Color(0xFFF3E8FF))
                    : cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user?.role.toUpperCase() ?? 'USER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: user?.role == 'admin'
                      ? (isDark ? const Color(0xFFD8B4FE) : const Color(0xFF9333EA))
                      : cs.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(user?.email ?? '', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
            const SizedBox(height: 28),

            // Info Card
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outline),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.person_outline, color: cs.primary),
                    title: Text('Nama Lengkap', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    subtitle: Text(user?.name ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
                    trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                    onTap: _showEditProfileDialog,
                  ),
                  Divider(height: 1, color: cs.outline),
                  ListTile(
                    leading: Icon(Icons.email_outlined, color: cs.primary),
                    title: Text('Email', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    subtitle: Text(user?.email ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
                    trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                    onTap: _showEditProfileDialog,
                  ),
                  Divider(height: 1, color: cs.outline),
                  ListTile(
                    leading: Icon(Icons.lock_outline, color: cs.primary),
                    title: Text('Keamanan Akun', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    subtitle: Text('Ganti Password', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
                    trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                    onTap: _showChangePasswordDialog,
                  ),
                  Divider(height: 1, color: cs.outline),
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode ? const Color(0xFF1C2333) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: cs.primary,
                        size: 20,
                      ),
                    ),
                    title: Text('Mode Gelap (Dark Mode)', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
                    subtitle: Text(themeProvider.isDarkMode ? 'Aktif' : 'Nonaktif', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) => context.read<ThemeProvider>().toggleTheme(value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  }
                },
                icon: Icon(Icons.logout, color: cs.error),
                label: Text('Keluar Akun', style: TextStyle(color: cs.error, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(color: cs.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
