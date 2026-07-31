import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../repositories/transaction_repository.dart';

class AdminReportPage extends StatefulWidget {
  const AdminReportPage({super.key});

  @override
  State<AdminReportPage> createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage> {
  bool _isLoading = true;
  Map<String, dynamic> _summary = {};
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final data = await TransactionRepository().getSalesReport();
    if (!mounted) return;
    setState(() {
      _summary = data['summary'] as Map<String, dynamic>? ?? {};
      _orders = data['orders'] as List<dynamic>? ?? [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final cs = Theme.of(context).colorScheme;

    final double totalRevenue = (_summary['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final int totalOrders = _summary['totalOrders'] ?? 0;
    final int completedOrders = _summary['completedOrders'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan Toko'),
        actions: [
          IconButton(icon: Icon(Icons.refresh, color: cs.primary), onPressed: _loadReport),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReport,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Rekapitulasi Penjualan & Keuangan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
                  ),
                  const SizedBox(height: 12),

                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'Total Omset Selesai',
                          currencyFormat.format(totalRevenue),
                          Icons.payments_outlined,
                          cs.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'Total Pesanan',
                          '$totalOrders Pesanan',
                          Icons.shopping_bag_outlined,
                          cs.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          'Pesanan Selesai',
                          '$completedOrders Pesanan',
                          Icons.task_alt,
                          cs.tertiary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rincian Seluruh Transaksi (${_orders.length})',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: cs.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Transaction Table View
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(cs.surfaceContainerHighest),
                      border: TableBorder.all(color: cs.outline, borderRadius: BorderRadius.circular(12)),
                      columns: const [
                        DataColumn(label: Text('Invoice', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Pelanggan', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Tanggal', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Metode', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _orders.map((o) {
                        final String dateStr = o['date'] ?? '';
                        String formattedDate = dateStr;
                        try {
                          formattedDate = dateFormat.format(DateTime.parse(dateStr));
                        } catch (_) {}

                        final String status = o['status'] ?? '';
                        final displayStatus = status == 'completed' ? 'Selesai' : status;

                        return DataRow(
                          cells: [
                            DataCell(Text(o['invoice'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Text(o['userName'] ?? 'User #${o['userId']}')),
                            DataCell(Text(formattedDate, style: const TextStyle(fontSize: 12))),
                            DataCell(Text(o['paymentMethod'] ?? 'Transfer')),
                            DataCell(Text(currencyFormat.format((o['total'] as num).toDouble()), style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: status == 'Selesai' || status == 'completed'
                                      ? cs.tertiary.withValues(alpha: 0.15)
                                      : cs.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  displayStatus,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: status == 'Selesai' || status == 'completed' ? cs.tertiary : cs.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
