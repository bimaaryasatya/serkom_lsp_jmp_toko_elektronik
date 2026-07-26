import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_widget.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Toko Elektronik',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, theme, _) {
              return IconButton(
                icon: Icon(
                  theme.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                tooltip: 'Ganti Mode Terang/Gelap (SharedPreferences)',
                onPressed: () {
                  theme.toggleTheme(!theme.isDarkMode);
                },
              );
            },
          ),
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF1E293B), size: 26),
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.cart);
                    },
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
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
              currentAccountPicture: CircleAvatar(
                backgroundColor: const Color(0xFF2563EB),
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              accountName: Text(
                user?.name ?? 'Pengguna Demo',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              accountEmail: Text(user?.email ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.grid_view_rounded, color: Color(0xFF2563EB)),
              title: const Text('Beranda & Produk'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF2563EB)),
              title: const Text('Keranjang Belanja'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.cart);
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined, color: Color(0xFF2563EB)),
              title: const Text('Riwayat Pesanan'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.orderHistory);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Color(0xFF2563EB)),
              title: const Text('Profil Saya'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.profile);
              },
            ),
            if (user?.role == 'admin') ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Color(0xFF9333EA)),
                title: const Text('Dashboard Admin', style: TextStyle(color: Color(0xFF9333EA), fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
                },
              ),
            ],
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
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          if (productProvider.isLoading) {
            return const LoadingWidget(message: 'Menghubungkan ke Database MySQL...');
          }

          return Column(
            children: [
              // Search Input & Hero Banner Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  children: [
                    // Promo Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'SERKOM PROMO ⚡',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Gadget & Elektronik Terbaik',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const Text(
                                  'Koleksi produk berkualitas dengan harga spesial.',
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.devices, size: 50, color: Color(0xFF38BDF8)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari gadget, laptop, smartphone...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  productProvider.searchProducts('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        productProvider.searchProducts(value);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),

              // Categories Horizontal Bar
              if (productProvider.categories.isNotEmpty)
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildCategoryChip(
                        null,
                        'Semua',
                        productProvider.selectedCategory == null,
                      ),
                      ...productProvider.categories.map(
                        (cat) => _buildCategoryChip(
                          cat,
                          cat.toUpperCase(),
                          productProvider.selectedCategory == cat,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Product Grid
              Expanded(
                child: productProvider.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off, size: 64, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 12),
                            const Text(
                              'Produk tidak ditemukan',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                productProvider.loadProducts();
                              },
                              child: const Text('Tampilkan Semua Produk'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => productProvider.loadProducts(),
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: productProvider.products.length,
                          itemBuilder: (context, index) {
                            final product = productProvider.products[index];
                            return ProductCard(
                              product: product,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.productDetail,
                                  arguments: product,
                                );
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String? category, String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          context.read<ProductProvider>().filterByCategory(category);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
