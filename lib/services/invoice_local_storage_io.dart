import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/transaction_item_model.dart';
import '../models/transaction_model.dart';
import 'invoice_service.dart';

class InvoiceLocalStorage {
  static Future<String> saveToLocalStorage({
    required TransactionModel transaction,
    required List<TransactionItemModel> items,
    String? customerName,
    String? customerEmail,
  }) async {
    final bytes = await InvoiceService.buildPdf(
      transaction: transaction,
      items: items,
      customerName: customerName,
      customerEmail: customerEmail,
    );

    Directory? dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = null;
    }
    if (dir == null) {
      throw Exception('Penyimpanan lokal tidak tersedia di perangkat ini');
    }

    final file = File('${dir.path}${Platform.pathSeparator}${InvoiceService.buildFileName(transaction)}');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
