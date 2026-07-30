import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/network_checker.dart';
import '../../models/banner_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../repositories/banner_repository.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_widget.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final _searchController = TextEditingController();
  final _bannerRepo = BannerRepository();
  final _pageController = PageController();

  List<BannerModel> _banners = [];
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  // Filter & Sort State
  String _selectedSort = 'latest'; // latest, price_asc, price_desc
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = context.read<AuthProvider>().user;
      context.read<ProductProvider>().loadProducts();
      if (user?.id != null) {
        context.read<WishlistProvider>().loadWishlist(user!.id!);
      }
      _loadBanners();
      _checkNetworkConnection();
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _checkNetworkConnection() async {
    bool isReachable = await NetworkChecker.isServerReachable();
    if (!isReachable && mounted) {
      NetworkChecker.showOfflineSnackBar(context);
    }
  }

  Future<void> _loadBanners() async {
    final banners = await _bannerRepo.getBanners();
    if (mounted && banners.isNotEmpty) {
      setState(() => _banners = banners);
      _startBannerAutoSlide();
    }
  }

  void _startBannerAutoSlide() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_banners.isEmpty || !_pageController.hasClients) return;
      int nextPage = (_currentBannerIndex + 1) % _banners.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _showFilterBottomSheet() {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter & Urutkan Produk 🔍', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              Text('Urutkan Berdasarkan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cs.onSurface)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Terbaru'),
                    selected: _selectedSort == 'latest',
                    onSelected: (val) => setState(() => _selectedSort = 'latest'),
                  ),
                  ChoiceChip(
                    label: const Text('Harga: Termurah'),
                    selected: _selectedSort == 'price_asc',
                    onSelected: (val) => setState(() => _selectedSort = 'price_asc'),
                  ),
                  ChoiceChip(
                    label: const Text('Harga: Termahal'),
                    selected: _selectedSort == 'price_desc',
                    onSelected: (val) => setState(() => _selectedSort = 'price_desc'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Rentang Harga (Rp)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cs.onSurface)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Min. Harga', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-')),
                  Expanded(
                    child: TextField(
                      controller: _maxPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Max. Harga', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _minPriceController.clear();
                        _maxPriceController.clear();
                        setState(() => _selectedSort = 'latest');
                        context.read<ProductProvider>().loadProducts();
                        Navigator.pop(context);
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<ProductProvider>().applyFilter(
                          minPrice: double.tryParse(_minPriceController.text),
                          maxPrice: double.tryParse(_maxPriceController.text),
                          sort: _selectedSort,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Terapkan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.bolt, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Tiptronic',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: cs.onSurface),
            ),
          ],
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, theme, _) {
              return IconButton(
                icon: Icon(theme.isDarkMode ? Icons.light_mode : Icons.dark_mode, color: cs.onSurface),
                onPressed: () => theme.toggleTheme(!theme.isDarkMode),
              );
            },
          ),
          Consumer<WishlistProvider>(
            builder: (context, wishlist, _) {
              return IconButton(
                icon: Icon(Icons.favorite_border, color: cs.onSurface),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.wishlist),
              );
            },
          ),
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.shopping_bag_outlined, color: cs.onSurface, size: 26),
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(color: cs.error, shape: BoxShape.circle),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1C2333), const Color(0xFF161B22)]
                      : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: cs.primary,
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              accountName: Text(
                user?.name ?? 'Pengguna',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
              ),
              accountEmail: Text(user?.email ?? '', style: const TextStyle(color: Colors.white70)),
            ),
            ListTile(
              leading: Icon(Icons.grid_view_rounded, color: cs.primary),
              title: const Text('Beranda & Produk'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.favorite_outline, color: cs.primary),
              title: const Text('Wishlist Saya'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.wishlist);
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart_outlined, color: cs.primary),
              title: const Text('Keranjang Belanja'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.cart);
              },
            ),
            ListTile(
              leading: Icon(Icons.receipt_long_outlined, color: cs.primary),
              title: const Text('Riwayat Pesanan'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.orderHistory);
              },
            ),
            ListTile(
              leading: Icon(Icons.person_outline, color: cs.primary),
              title: const Text('Profil Saya'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.profile);
              },
            ),
            if (user?.role == 'admin') ...[
              const Divider(),
              ListTile(
                leading: Icon(Icons.admin_panel_settings, color: cs.tertiary),
                title: Text('Dashboard Admin', style: TextStyle(color: cs.tertiary, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
                },
              ),
            ],
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
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, _) {
          if (productProvider.isLoading) {
            return const LoadingWidget(message: 'Memuat data produk...');
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  children: [
                    // Dynamic Promo Banner Carousel
                    if (_banners.isNotEmpty)
                      SizedBox(
                        height: 120,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) => setState(() => _currentBannerIndex = index),
                          itemCount: _banners.length,
                          itemBuilder: (context, index) {
                            final b = _banners[index];
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(right: 4),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [const Color(0xFF1C2333), const Color(0xFF0D1117)]
                                      : [const Color(0xFF1E3A8A), const Color(0xFF0F172A)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: isDark ? Border.all(color: const Color(0xFF30363D)) : null,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          b.title,
                                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          b.subtitle,
                                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: CachedNetworkImage(
                                      imageUrl: b.image,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Icon(Icons.devices, size: 40, color: cs.primary),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Search Bar + Filter Button Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Cari gadget, laptop, smartphone...',
                              prefixIcon: Icon(Icons.search, color: cs.primary),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        productProvider.searchProducts('');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            onChanged: (value) {
                              productProvider.searchProducts(value);
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _showFilterBottomSheet,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                            ),
                            child: Icon(Icons.tune_rounded, color: cs.primary, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Category chips
              if (productProvider.categories.isNotEmpty)
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildCategoryChip(context, null, 'Semua', productProvider.selectedCategory == null),
                      ...productProvider.categories.map(
                        (cat) => _buildCategoryChip(
                          context, cat, cat.toUpperCase(), productProvider.selectedCategory == cat,
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
                            Icon(Icons.search_off, size: 64, color: cs.onSurface.withValues(alpha: 0.25)),
                            const SizedBox(height: 12),
                            Text(
                              'Produk tidak ditemukan',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant),
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

  Widget _buildCategoryChip(BuildContext context, String? category, String label, bool isSelected) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => context.read<ProductProvider>().filterByCategory(category),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? cs.primary : cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? cs.primary : cs.outline),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : cs.onSurfaceVariant,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
