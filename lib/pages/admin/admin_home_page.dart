import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/transaction_repository.dart';
import '../../repositories/user_repository.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _productCount = 0;
  int _userCount = 0;
  double _totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final productCount = await ProductRepository().getProductCount();
    final userCount = await UserRepository().getUserCount();
    final totalRevenue = await TransactionRepository().getTotalRevenue();

    if (!mounted) return;
    setState(() {
      _productCount = productCount;
      _userCount = userCount;
      _totalRevenue = totalRevenue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: cs.primary),
            onPressed: () {
              context.read<ProductProvider>().loadProducts();
              _loadData();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1C2333), const Color(0xFF0D1117)]
                      : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: cs.primary,
                child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
              ),
              accountName: Text(
                context.watch<AuthProvider>().user?.name ?? 'Admin',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              accountEmail: const Text(
                'Administrator Toko',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard_rounded, color: cs.primary),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.inventory_2_outlined, color: cs.primary),
              title: const Text('Kelola Produk'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.adminProductManage);
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_bag_outlined, color: cs.primary),
              title: const Text('Kelola Pesanan'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.adminOrders);
              },
            ),
            ListTile(
              leading: Icon(Icons.assessment_outlined, color: cs.primary),
              title: const Text('Laporan Penjualan'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.adminReport);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.storefront, color: cs.tertiary),
              title: Text('Tampilan Pembeli', style: TextStyle(color: cs.tertiary)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, AppRoutes.userHome);
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: cs.error),
              title: Text('Keluar Akun', style: TextStyle(color: cs.error, fontWeight: FontWeight.bold)),
              onTap: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Halo, ${context.read<AuthProvider>().user?.name ?? 'Admin'} 👋',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            Text(
              'Ringkasan statistik toko elektronik',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Stat Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    label: 'Total Produk',
                    value: '$_productCount',
                    icon: Icons.inventory_2_outlined,
                    gradient: [cs.primary, cs.primary.withValues(alpha: 0.75)],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    label: 'Total User',
                    value: '$_userCount',
                    icon: Icons.people_outline,
                    gradient: [cs.tertiary, cs.tertiary.withValues(alpha: 0.75)],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              context: context,
              label: 'Total Pendapatan Selesai',
              value: currencyFormat.format(_totalRevenue),
              icon: Icons.account_balance_wallet_outlined,
              gradient: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
            ),
            const SizedBox(height: 24),

            // Quick Menu
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                    child: Text(
                      'Menu Operasional Admin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.add_box_outlined,
                    iconColor: cs.primary,
                    title: 'Kelola Produk Store',
                    subtitle: 'Tambah, perbarui, atau hapus stok produk',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.adminProductManage),
                  ),
                  Divider(height: 1, color: cs.outline),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.shopping_bag_outlined,
                    iconColor: isDark ? const Color(0xFFD8B4FE) : const Color(0xFF9333EA),
                    title: 'Kelola Pesanan Masuk',
                    subtitle: 'Konfirmasi, proses, dan update status pesanan',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.adminOrders),
                  ),
                  Divider(height: 1, color: cs.outline),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.assessment_outlined,
                    iconColor: const Color(0xFF0284C7),
                    title: 'Laporan Penjualan & Keuangan',
                    subtitle: 'Lihat rekapitulasi omset dan rincian transaksi',
                    onTap: () => Navigator.pushNamed(context, AppRoutes.adminReport),
                  ),
                  Divider(height: 1, color: cs.outline),
                  _buildMenuTile(
                    context: context,
                    icon: Icons.refresh,
                    iconColor: cs.tertiary,
                    title: 'Refresh Data',
                    subtitle: 'Muat ulang statistik dan produk terbaru',
                    onTap: () {
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Data berhasil diperbarui')),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              Icon(icon, color: Colors.white, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
