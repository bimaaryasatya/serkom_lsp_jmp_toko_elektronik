import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../providers/product_provider.dart';
import '../../repositories/transaction_repository.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final _transactionRepo = TransactionRepository();
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    _transactions = await _transactionRepo.getAllTransactions();
    setState(() => _isLoading = false);
  }

  Future<void> _updateStatus(int id, String newStatus) async {
    await _transactionRepo.updateTransactionStatus(id, newStatus);
    await _loadOrders();
    if (mounted) {
      context.read<ProductProvider>().loadProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status diperbarui: $newStatus'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
    }
  }

  void _showInputTrackingDialog(TransactionModel t) {
    final trackingController = TextEditingController(text: t.trackingNumber);
    final courierController = TextEditingController(text: t.courier);

    showDialog(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surface,
          title: const Text('Input Nomor Resi Pengiriman 📦'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: courierController,
                decoration: const InputDecoration(labelText: 'Nama Kurir (JNE/J&T/Pos)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: trackingController,
                decoration: const InputDecoration(labelText: 'Nomor Resi Pengiriman'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                await _transactionRepo.updateTrackingNumber(
                  t.id!,
                  courierController.text.trim(),
                  trackingController.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  _loadOrders();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nomor resi berhasil di-update dan pesanan Dikirim!')),
                  );
                }
              },
              child: const Text('Simpan & Kirim'),
            ),
          ],
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pesanan Masuk'),
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: cs.primary), onPressed: _loadOrders),
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
                      Icon(Icons.inbox, size: 72, color: cs.onSurface.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      Text('Belum ada pesanan masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final t = _transactions[index];
                      final displayStatus = t.status == 'completed' ? 'Selesai' : t.status;
                      final (bgColor, textColor) = _getStatusColors(context, t.status);

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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t.invoice, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cs.onSurface), overflow: TextOverflow.ellipsis),
                                      Text('User ID: #${t.userId}', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
                                  child: Text(displayStatus, style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dateFormat.format(DateTime.parse(t.date)),
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Metode: ${t.paymentMethod} | Kurir: ${t.courier}' + (t.trackingNumber.isNotEmpty ? ' (${t.trackingNumber})' : ''),
                              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                            ),

                            if (t.address != null && t.address!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1C2333) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: cs.outline),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.location_on_outlined, color: cs.primary, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text('Alamat: ${t.address}', style: TextStyle(fontSize: 11, color: cs.onSurface, height: 1.4)),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            Divider(height: 20, color: cs.outline),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Total Tagihan', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                                    if (t.shippingFee > 0)
                                      Text('Ongkir: ${currencyFormat.format(t.shippingFee)}', style: TextStyle(fontSize: 11, color: cs.tertiary, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                Text(currencyFormat.format(t.total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cs.primary)),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Action Buttons
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (t.status == 'Menunggu Konfirmasi' || t.status == 'pending')
                                  _actionBtn(
                                    label: 'Konfirmasi & Diproses',
                                    icon: Icons.check_circle_outline,
                                    color: cs.primary,
                                    onTap: () => _updateStatus(t.id!, 'Diproses'),
                                  ),
                                if (t.status == 'Diproses')
                                  _actionBtn(
                                    label: 'Input Resi & Kirim',
                                    icon: Icons.local_shipping_outlined,
                                    color: isDark ? const Color(0xFFD8B4FE) : const Color(0xFF9333EA),
                                    onTap: () => _showInputTrackingDialog(t),
                                  ),
                                if (t.status == 'Dikirim')
                                  _actionBtn(
                                    label: 'Tandai Selesai',
                                    icon: Icons.task_alt,
                                    color: cs.tertiary,
                                    onTap: () => _updateStatus(t.id!, 'Selesai'),
                                  ),
                                PopupMenuButton<String>(
                                  onSelected: (s) => _updateStatus(t.id!, s),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(border: Border.all(color: cs.outline), borderRadius: BorderRadius.circular(10)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Ubah Status', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                                        Icon(Icons.arrow_drop_down, size: 16, color: cs.onSurfaceVariant),
                                      ],
                                    ),
                                  ),
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(value: 'Menunggu Konfirmasi', child: Text('Menunggu Konfirmasi')),
                                    PopupMenuItem(value: 'Diproses', child: Text('Diproses')),
                                    PopupMenuItem(value: 'Dikirim', child: Text('Dikirim')),
                                    PopupMenuItem(value: 'Selesai', child: Text('Selesai')),
                                    PopupMenuItem(value: 'Dibatalkan', child: Text('Dibatalkan')),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
