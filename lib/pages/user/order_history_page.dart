import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../models/transaction_item_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../repositories/product_repository.dart';
import '../../repositories/review_repository.dart';
import '../../repositories/transaction_repository.dart';
import '../../services/invoice_service.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final _transactionRepo = TransactionRepository();
  final _reviewRepo = ReviewRepository();
  final _productRepo = ProductRepository();

  List<TransactionModel> _transactions = [];
  Set<String> _reviewedPairs = {}; // "transactionId_productId"
  final Map<int, List<TransactionItemModel>> _transactionItemsMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final user = context.read<AuthProvider>().user;
    if (user?.id != null) {
      _transactions = await _transactionRepo.getTransactionsByUser(user!.id!);
      _reviewedPairs = await _reviewRepo.getUserReviewedPairs(user.id!);

      for (var t in _transactions) {
        if (t.id != null) {
          final items = await _transactionRepo.getTransactionItems(t.id!);
          _transactionItemsMap[t.id!] = items;
        }
      }
    }
    setState(() => _isLoading = false);
  }

  (Color bg, Color text) _getStatusColors(BuildContext context, String status) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case 'Diproses':
        return (isDark ? cs.primaryContainer.withValues(alpha: 0.3) : const Color(0xFFEFF6FF), cs.primary);
      case 'Dikirim':
        return (isDark ? const Color(0xFF2D1854) : const Color(0xFFF3E8FF), isDark ? const Color(0xFFD8B4FE) : const Color(0xFF9333EA));
      case 'Selesai':
      case 'completed':
        return (isDark ? cs.tertiaryContainer.withValues(alpha: 0.3) : const Color(0xFFECFDF5), cs.tertiary);
      case 'Dibatalkan':
        return (isDark ? cs.errorContainer.withValues(alpha: 0.3) : const Color(0xFFFEF2F2), cs.error);
      default:
        return (isDark ? const Color(0xFF2D1F00) : const Color(0xFFFFFBEB), isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706));
    }
  }

  void _navigateToProductDetail(int productId) async {
    ProductModel? product = context.read<ProductProvider>().getProductById(productId);
    product ??= await _productRepo.getProductById(productId);

    if (mounted && product != null) {
      Navigator.pushNamed(context, AppRoutes.productDetail, arguments: product);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk tidak ditemukan')),
      );
    }
  }

  void _showAddReviewDialog(TransactionModel transaction, TransactionItemModel item) {
    int selectedRating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final cs = Theme.of(context).colorScheme;
            return AlertDialog(
              backgroundColor: cs.surface,
              title: Text('Ulas ${item.productName} ⭐'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invoice: ${transaction.invoice}', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  const Text('Pilih Bintang Rating:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        icon: Icon(
                          index < selectedRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 28,
                        ),
                        onPressed: () => setDialogState(() => selectedRating = index + 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Tulis ulasan produk ini...',
                      labelText: 'Ulasan / Catatan',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () async {
                    final user = context.read<AuthProvider>().user!;
                    final String pairKey = '${transaction.id}_${item.productId}';

                    await _reviewRepo.addReview(
                      ReviewModel(
                        userId: user.id!,
                        userName: user.name,
                        productId: item.productId,
                        transactionId: transaction.id,
                        rating: selectedRating,
                        comment: commentController.text.trim(),
                        date: DateTime.now().toString(),
                      ),
                    );

                    if (mounted) {
                      setState(() {
                        _reviewedPairs.add(pairKey);
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Terima kasih atas ulasan ${item.productName}! ⭐')),
                      );
                    }
                  },
                  child: const Text('Kirim Ulasan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showInvoiceOptions(TransactionModel transaction, List<TransactionItemModel> items) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: cs.outline, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.receipt_long, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transaction.invoice,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: cs.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Transaksi berstatus Selesai. Simpan atau unduh invoice sebagai PDF.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: cs.primary.withValues(alpha: 0.08),
                  leading: Icon(Icons.download_outlined, color: cs.primary),
                  title: const Text('Download Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Pilih lokasi penyimpanan di perangkat'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _saveInvoice(transaction, items, viaDialog: true);
                  },
                ),
                const SizedBox(height: 8),
                if (!InvoiceService.isWeb)
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tileColor: cs.tertiary.withValues(alpha: 0.08),
                    leading: Icon(Icons.folder_outlined, color: cs.tertiary),
                    title: const Text('Simpan ke Penyimpanan Lokal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Tersimpan di folder dokumen aplikasi'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _saveInvoice(transaction, items, viaDialog: false);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveInvoice(
    TransactionModel transaction,
    List<TransactionItemModel> items, {
    required bool viaDialog,
  }) async {
    final user = context.read<AuthProvider>().user;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
            SizedBox(width: 16),
            Flexible(child: Text('Menyiapkan invoice...')),
          ],
        ),
      ),
    );

    String? message;
    try {
      if (viaDialog) {
        final path = await InvoiceService.downloadViaDialog(
          transaction: transaction,
          items: items,
          customerName: user?.name,
          customerEmail: user?.email,
        );
        if (kIsWeb) {
          message = 'Invoice ${transaction.invoice}.pdf berhasil diunduh di browser';
        } else {
          message = path == null ? 'Penyimpanan dibatalkan' : 'Invoice tersimpan di:\n$path';
        }
      } else {
        final path = await InvoiceService.saveToLocalStorage(
          transaction: transaction,
          items: items,
          customerName: user?.name,
          customerEmail: user?.email,
        );
        message = 'Invoice tersimpan di penyimpanan lokal:\n$path';
      }
    } catch (e) {
      message = 'Gagal menyimpan invoice: $e';
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTransactions),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 72, color: cs.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text('Belum ada riwayat pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final t = _transactions[index];
                      final displayStatus = t.status == 'completed' ? 'Selesai' : t.status;
                      final (bgColor, textColor) = _getStatusColors(context, t.status);
                      final List<TransactionItemModel> items = _transactionItemsMap[t.id] ?? [];
                      final bool isCompleted = t.status == 'Selesai' || t.status == 'completed';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.outline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Invoice Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(t.invoice, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: cs.onSurface), overflow: TextOverflow.ellipsis),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
                                  child: Text(displayStatus, style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateFormat.format(DateTime.parse(t.date)),
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.local_shipping_outlined, size: 14, color: cs.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Kurir: ${t.courier}' + (t.trackingNumber.isNotEmpty ? ' (${t.trackingNumber})' : ''),
                                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                            Divider(height: 20, color: cs.outline),

                            // Items List Card inside Invoice
                            Text(
                              'Produk yang Dibeli (${items.length}):',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.onSurface),
                            ),
                            const SizedBox(height: 8),
                            ...items.map((item) {
                              final String pairKey = '${t.id}_${item.productId}';
                              final bool itemReviewed = _reviewedPairs.contains(pairKey);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1C2333) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: cs.outline),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 48,
                                        height: 48,
                                        child: item.productImage.isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: item.productImage,
                                                fit: BoxFit.cover,
                                                errorWidget: (_, __, ___) => Icon(Icons.devices, size: 24, color: cs.primary),
                                              )
                                            : Icon(Icons.devices, size: 24, color: cs.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: cs.onSurface),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${currencyFormat.format(item.price)}  x${item.quantity}',
                                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Individual Review Button per Item in Invoice
                                    if (isCompleted)
                                      if (itemReviewed)
                                        ElevatedButton.icon(
                                          onPressed: () => _navigateToProductDetail(item.productId),
                                          icon: const Icon(Icons.visibility_outlined, size: 12),
                                          label: const Text('Lihat Ulasan', style: TextStyle(fontSize: 10)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: cs.secondaryContainer,
                                            foregroundColor: cs.onSecondaryContainer,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            elevation: 0,
                                          ),
                                        )
                                      else
                                        OutlinedButton.icon(
                                          onPressed: () => _showAddReviewDialog(t, item),
                                          icon: const Icon(Icons.star_outline, size: 12),
                                          label: const Text('Ulas', style: TextStyle(fontSize: 10)),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                  ],
                                ),
                              );
                            }),

                            Divider(height: 20, color: cs.outline),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Total Pembayaran (${t.paymentMethod})', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                                    Text(currencyFormat.format(t.total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cs.primary)),
                                  ],
                                ),
                              ],
                            ),

                            if (isCompleted) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _showInvoiceOptions(t, items),
                                  icon: const Icon(Icons.download_outlined, size: 16),
                                  label: const Text('Simpan / Download Invoice (PDF)'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    side: BorderSide(color: cs.primary),
                                    foregroundColor: cs.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
