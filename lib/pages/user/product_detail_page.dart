import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../repositories/review_repository.dart';
import '../../widgets/product_image.dart';

class ProductDetailPage extends StatefulWidget {
  final ProductModel product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _reviewRepo = ReviewRepository();
  int _quantity = 1;
  int _currentImageIndex = 0;
  late PageController _pageController;

  List<ReviewModel> _reviews = [];
  double _avgRating = 0.0;
  int _reviewCount = 0;
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadReviews();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    final data = await _reviewRepo.getProductReviews(widget.product.id);
    if (mounted) {
      setState(() {
        _reviews = data['reviews'] as List<ReviewModel>;
        _avgRating = data['avgRating'] as double;
        _reviewCount = data['count'] as int;
        _isLoadingReviews = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final user = context.watch<AuthProvider>().user;
    final wishlistProvider = context.watch<WishlistProvider>();
    final cs = Theme.of(context).colorScheme;

    final isWishlisted = wishlistProvider.isProductWishlisted(product.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          if (user != null)
            IconButton(
              icon: Icon(
                isWishlisted ? Icons.favorite : Icons.favorite_border,
                color: isWishlisted ? Colors.redAccent : cs.onSurface,
              ),
              onPressed: () {
                context.read<WishlistProvider>().toggleWishlist(user.id!, product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isWishlisted
                          ? '${product.name} dihapus dari wishlist'
                          : '${product.name} disimpan ke wishlist ❤️',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSlider(product.imageList, cs),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currencyFormat.format(product.price),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      // Rating Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFD97706), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$_avgRating ($_reviewCount ulasan)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.inventory, size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('Stok: ${product.stock}', style: TextStyle(color: cs.onSurface)),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.category.toUpperCase(),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Deskripsi Produk',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Jumlah Pembelian',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton.filled(
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        icon: const Icon(Icons.remove),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$_quantity',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      IconButton.filled(
                        onPressed: _quantity < product.stock ? () => setState(() => _quantity++) : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Reviews & Ratings Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ulasan Pembeli ⭐',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text('$_reviewCount ulasan', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_isLoadingReviews)
                    const Center(child: CircularProgressIndicator())
                  else if (_reviews.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Belum ada ulasan untuk produk ini',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _reviews.map((r) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cs.outline),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(r.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (index) => Icon(
                                        index < r.rating ? Icons.star : Icons.star_border,
                                        size: 14,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (r.comment.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(r.comment, style: TextStyle(fontSize: 12, color: cs.onSurface)),
                              ],
                              const SizedBox(height: 4),
                              Text(r.date, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () {
              context.read<CartProvider>().addToCart(product.id, _quantity);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$_quantity ${product.name} ditambahkan ke keranjang'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Tambah ke Keranjang'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSlider(List<String> images, ColorScheme cs) {
    if (images.isEmpty) {
      return const ProductImage(
        imageUrl: '',
        width: double.infinity,
        height: 300,
        fit: BoxFit.contain,
      );
    }

    return Column(
      children: [
        Stack(
          children: [
            SizedBox(
              height: 300,
              child: PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _openImagePreview(context, images, index),
                    child: Hero(
                      tag: 'product_img_${widget.product.id}_$index',
                      child: ProductImage(
                        imageUrl: images[index],
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (images.length > 1) ...[
              // Left Arrow Button
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                      onPressed: _currentImageIndex > 0
                          ? () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                    ),
                  ),
                ),
              ),
              // Right Arrow Button
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                      onPressed: _currentImageIndex < images.length - 1
                          ? () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                    ),
                  ),
                ),
              ),
              // Page Counter Badge
              Positioned(
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1} / ${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isSelected = _currentImageIndex == index;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? cs.primary : Colors.grey.withValues(alpha: 0.3),
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: ProductImage(
                        imageUrl: images[index],
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _openImagePreview(BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        int pageIdx = initialIndex;
        final previewController = PageController(initialPage: initialIndex);
        return StatefulBuilder(
          builder: (ctx, setPreviewState) {
            return Dialog.fullscreen(
              backgroundColor: Colors.black,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: previewController,
                    itemCount: images.length,
                    onPageChanged: (idx) {
                      setPreviewState(() => pageIdx = idx);
                    },
                    itemBuilder: (ctx, idx) {
                      return InteractiveViewer(
                        maxScale: 4.0,
                        child: Center(
                          child: ProductImage(
                            imageUrl: images[idx],
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(dialogCtx),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${pageIdx + 1} / ${images.length}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
