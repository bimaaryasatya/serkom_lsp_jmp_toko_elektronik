import '../models/transaction_item_model.dart';
import '../models/transaction_model.dart';

class InvoiceLocalStorage {
  static Future<String> saveToLocalStorage({
    required TransactionModel transaction,
    required List<TransactionItemModel> items,
    String? customerName,
    String? customerEmail,
  }) {
    throw UnsupportedError('Penyimpanan lokal ke folder dokumen tidak didukung di Web. Gunakan Download Invoice.');
  }
}
