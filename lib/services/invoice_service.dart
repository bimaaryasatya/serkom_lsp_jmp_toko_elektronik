import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/transaction_item_model.dart';
import '../models/transaction_model.dart';
import 'invoice_local_storage_stub.dart'
    if (dart.library.io) 'invoice_local_storage_io.dart' as invoice_local_storage;

class InvoiceService {
  static String formatRupiah(num amount) {
    final value = amount.round().toString();
    final buffer = StringBuffer('Rp ');
    for (var i = 0; i < value.length; i++) {
      buffer.write(value[i]);
      final remaining = value.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
    }
    return buffer.toString();
  }

  static String buildFileName(TransactionModel transaction) {
    final raw = transaction.invoice.isNotEmpty ? transaction.invoice : 'invoice';
    final safe = raw.replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '_');
    return '$safe.pdf';
  }

  static Future<Uint8List> buildPdf({
    required TransactionModel transaction,
    required List<TransactionItemModel> items,
    String? customerName,
    String? customerEmail,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context ctx) {
          final displayStatus = transaction.status == 'completed' ? 'Selesai' : transaction.status;
          final statusColor = transaction.status == 'Selesai' || transaction.status == 'completed'
              ? PdfColors.green700
              : PdfColors.orange700;

          double subtotal = 0.0;
          final tableData = <List<String>>[];
          for (var i = 0; i < items.length; i++) {
            final item = items[i];
            final lineTotal = item.price * item.quantity;
            subtotal += lineTotal;
            tableData.add([
              '${i + 1}',
              item.productName,
              '${item.quantity}',
              formatRupiah(item.price),
              formatRupiah(lineTotal),
            ]);
          }

          return [
            // ============ HEADER ============
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'TIPTRONIC',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800),
                    ),
                    pw.Text(
                      'Toko Elektronik',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Jl. Toko Elektronik No. 1, Jakarta',
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(color: statusColor.withValues(0.12, null, null, null), borderRadius: pw.BorderRadius.circular(4)),
                      child: pw.Text(
                        displayStatus,
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: statusColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Divider(color: PdfColors.grey400, thickness: 0.8),
            pw.SizedBox(height: 14),

            // ============ INFO BOXES ============
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Informasi Pesanan',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800),
                        ),
                        pw.SizedBox(height: 6),
                        _infoRow('No. Invoice', transaction.invoice, bold: true),
                        _infoRow('Tanggal', _formatDate(transaction.date)),
                        _infoRow('Metode Bayar', transaction.paymentMethod),
                        _infoRow('Kurir', transaction.courier),
                        if (transaction.trackingNumber.isNotEmpty)
                          _infoRow('No. Resi', transaction.trackingNumber),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Data Pelanggan',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800),
                        ),
                        pw.SizedBox(height: 6),
                        if (customerName != null && customerName.isNotEmpty)
                          _infoRow('Nama', customerName, bold: true),
                        if (customerEmail != null && customerEmail.isNotEmpty)
                          _infoRow('Email', customerEmail),
                        if (transaction.address != null && transaction.address!.isNotEmpty)
                          _infoRow('Alamat', transaction.address!),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 18),

            // ============ ITEMS TABLE ============
            pw.Text(
              'Rincian Barang',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['No', 'Produk', 'Qty', 'Harga', 'Subtotal'],
              data: tableData,
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: PdfColors.teal700),
              headerPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              cellStyle: pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              headerAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.IntrinsicColumnWidth(),
                3: const pw.FlexColumnWidth(),
                4: const pw.FlexColumnWidth(),
              },
            ),
            pw.SizedBox(height: 14),

            // ============ TOTALS ============
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 220,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _totalRow('Subtotal', formatRupiah(subtotal)),
                    _totalRow('Ongkos Kirim', formatRupiah(transaction.shippingFee)),
                    pw.Divider(color: PdfColors.grey400),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 3),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'TOTAL',
                            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                          ),
                          pw.Text(
                            formatRupiah(transaction.total),
                            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 24),

            // ============ FOOTER ============
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),
            pw.Text(
              'Terima kasih telah berbelanja di TIPTRONIC. '
              'Simpan invoice ini sebagai bukti transaksi resmi Anda.',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ];
        },
      ),
    );
    return doc.save();
  }

  static pw.Widget _infoRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 78,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  static String _formatDate(String date) {
    if (date.isEmpty) return '-';
    try {
      return DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  static Future<String?> downloadViaDialog({
    required TransactionModel transaction,
    required List<TransactionItemModel> items,
    String? customerName,
    String? customerEmail,
  }) async {
    final bytes = await buildPdf(
      transaction: transaction,
      items: items,
      customerName: customerName,
      customerEmail: customerEmail,
    );

    return FilePicker.saveFile(
      dialogTitle: 'Simpan Invoice',
      fileName: buildFileName(transaction),
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
  }

  static Future<String> saveToLocalStorage({
    required TransactionModel transaction,
    required List<TransactionItemModel> items,
    String? customerName,
    String? customerEmail,
  }) {
    return invoice_local_storage.InvoiceLocalStorage.saveToLocalStorage(
      transaction: transaction,
      items: items,
      customerName: customerName,
      customerEmail: customerEmail,
    );
  }

  static bool get isWeb => kIsWeb;
}
