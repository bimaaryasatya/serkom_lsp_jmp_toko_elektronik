import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/constants.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';

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
    int productCount = 0;
    int userCount = 0;
    double totalRevenue = 0;

    try {
      final pRes = await http.get(Uri.parse('${AppConstants.apiBaseUrl}/products/count'));
      if (pRes.statusCode == 200) {
        productCount = json.decode(pRes.body)['count'] ?? 0;
      }

      final uRes = await http.get(Uri.parse('${AppConstants.apiBaseUrl}/users/count'));
      if (uRes.statusCode == 200) {
        userCount = json.decode(uRes.body)['count'] ?? 0;
      }

      final rRes = await http.get(Uri.parse('${AppConstants.apiBaseUrl}/stats/revenue'));
      if (rRes.statusCode == 200) {
        final data = json.decode(rRes.body);
        totalRevenue = (data['totalRevenue'] as num).toDouble();
      }
    } catch (_) {}

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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2563EB)),
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Color(0xFF2563EB),
                child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 30),
              ),
              accountName: Text(
                context.watch<AuthProvider>().user?.name ?? 'Admin',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: const Text('Administrator Database MySQL'),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded, color: Color(0xFF2563EB)),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB)),
              title: const Text('Kelola Produk'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.adminProductManage);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF2563EB)),
              title: const Text('Kelola Pesanan Masuk'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.adminOrders);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.storefront, color: Color(0xFF10B981)),
              title: const Text('Tampilan Pembeli (Store)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, AppRoutes.userHome);
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
              title: const Text('Keluar Akun', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
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
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const Text(
              'Ringkasan statistik data toko elektronik dari MySQL',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Stat Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildGradientStatCard(
                    'Total Produk',
                    '$_productCount',
                    Icons.inventory_2_outlined,
                    [const Color(0xFF2563EB), const Color(0xFF3B82F6)],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGradientStatCard(
                    'Total User',
                    '$_userCount',
                    Icons.people_outline,
                    [const Color(0xFF10B981), const Color(0xFF059669)],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildGradientStatCard(
              'Total Pendapatan Terjual',
              currencyFormat.format(_totalRevenue),
              Icons.account_balance_wallet_outlined,
              [const Color(0xFFF59E0B), const Color(0xFFD97706)],
            ),
            const SizedBox(height: 24),

            // Quick Menu Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(18, 18, 18, 8),
                    child: Text(
                      'Menu Operasional Admin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_box_outlined, color: Color(0xFF2563EB)),
                    ),
                    title: const Text('Kelola Produk Store', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Tambah, perbarui, atau hapus stok produk di MySQL'),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.adminProductManage);
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9333EA).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF9333EA)),
                    ),
                    title: const Text('Kelola Pesanan Masuk', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Konfirmasi pembayaran, ubah status diproses/dikirim/selesai'),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.adminOrders);
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.refresh, color: Color(0xFF10B981)),
                    ),
                    title: const Text('Refresh Data MySQL', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Muat ulang data produk dan statistik terbaru'),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                    onTap: () {
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Data berhasil diperbarui'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
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

  Widget _buildGradientStatCard(
    String title,
    String value,
    IconData icon,
    List<Color> gradientColors,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.25),
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
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
