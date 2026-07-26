import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/transaction_repository.dart';
import '../../models/transaction_model.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final _transactionRepo = TransactionRepository();
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final userId = context.read<AuthProvider>().user!.id!;
    _transactions = await _transactionRepo.getTransactionsByUser(userId);
    setState(() => _isLoading = false);
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
          'Riwayat Pesanan Saya',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 64, color: Color(0xFF94A3B8)),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada riwayat pesanan',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
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

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                                Text(
                                  t.invoice,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Color(0xFF0F172A),
                                  ),
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
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Pembayaran',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
