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
          content: Text('Status pesanan diperbarui menjadi: $newStatus'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'Diproses':
        return const Color(0xFFEFF6FF);
      case 'Dikirim':
        return const Color(0xFFF3E8FF);
      case 'Selesai':
      case 'completed':
        return const Color(0xFFECFDF5);
      case 'Dibatalkan':
        return const Color(0xFFFEF2F2);
      case 'Menunggu Konfirmasi':
      default:
        return const Color(0xFFFFFBEB);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'Diproses':
        return const Color(0xFF2563EB);
      case 'Dikirim':
        return const Color(0xFF9333EA);
      case 'Selesai':
      case 'completed':
        return const Color(0xFF059669);
      case 'Dibatalkan':
        return const Color(0xFFDC2626);
      case 'Menunggu Konfirmasi':
      default:
        return const Color(0xFFD97706);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Kelola Pesanan Masuk',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2563EB)),
            onPressed: _loadOrders,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Color(0xFF94A3B8)),
                      SizedBox(height: 12),
                      Text(
                        'Belum ada pesanan masuk',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
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

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.invoice,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      'User ID: #${t.userId}',
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusBgColor(t.status),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    displayStatus,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _getStatusTextColor(t.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dateFormat.format(DateTime.parse(t.date)),
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                            if (t.address != null && t.address!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on_outlined, color: Color(0xFF2563EB), size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Alamat GPS: ${t.address}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF334155), height: 1.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Tagihan', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                    if (t.shippingFee > 0)
                                      Text(
                                        'Ongkir: ${currencyFormat.format(t.shippingFee)}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                                      ),
                                  ],
                                ),
                                Text(
                                  currencyFormat.format(t.total),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Dynamic Status Action Buttons
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (t.status == 'Menunggu Konfirmasi' || t.status == 'pending')
                                  ElevatedButton.icon(
                                    onPressed: () => _updateStatus(t.id!, 'Diproses'),
                                    icon: const Icon(Icons.check_circle_outline, size: 16),
                                    label: const Text('Konfirmasi & Diproses'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                if (t.status == 'Diproses')
                                  ElevatedButton.icon(
                                    onPressed: () => _updateStatus(t.id!, 'Dikirim'),
                                    icon: const Icon(Icons.local_shipping_outlined, size: 16),
                                    label: const Text('Kirim Pesanan'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF9333EA),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                if (t.status == 'Dikirim')
                                  ElevatedButton.icon(
                                    onPressed: () => _updateStatus(t.id!, 'Selesai'),
                                    icon: const Icon(Icons.task_alt, size: 16),
                                    label: const Text('Tandai Selesai'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),

                                // Manual Status Selector
                                PopupMenuButton<String>(
                                  onSelected: (String status) => _updateStatus(t.id!, status),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Ubah Status', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                                        Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF475569)),
                                      ],
                                    ),
                                  ),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'Menunggu Konfirmasi', child: Text('Menunggu Konfirmasi')),
                                    const PopupMenuItem(value: 'Diproses', child: Text('Diproses')),
                                    const PopupMenuItem(value: 'Dikirim', child: Text('Dikirim')),
                                    const PopupMenuItem(value: 'Selesai', child: Text('Selesai')),
                                    const PopupMenuItem(value: 'Dibatalkan', child: Text('Dibatalkan')),
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
}
