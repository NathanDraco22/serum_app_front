import '../../data/receipts_data_source.dart';
import '../../domain/models/receipt_model/receipt_model.dart';
import '../../domain/query_params/receipt_query_params.dart';
import '../../domain/responses/list_response.dart';
import '../../tools/reactive_repo/reactive_repository.dart';

class ReceiptsRepository with ReactiveRepository<ReceiptInDb> {
  final ReceiptsDataSource receiptsDataSource;

  ReceiptsRepository(this.receiptsDataSource);

  List<ReceiptInDb> _receipts = [];

  Future<ReceiptInDb> createReceipt(CreateReceipt createReceipt) async {
    final result =
        await receiptsDataSource.createReceipt(createReceipt.toJson());
    final newReceipt = ReceiptInDb.fromJson(result);
    _receipts = [newReceipt, ..._receipts];
    notifyItemCreated(newReceipt);
    return newReceipt;
  }

  Future<List<ReceiptInDb>> getAllReceipts(
      {ReceiptQueryParams? queryParams}) async {
    final results =
        await receiptsDataSource.getAllReceipts(queryParams: queryParams);
    final response = ListResponse<ReceiptInDb>.fromJson(
      results,
      ReceiptInDb.fromJson,
    );

    _receipts = response.data;
    return _receipts;
  }

  Future<ReceiptInDb?> getReceiptById(String receiptId) async {
    final result = await receiptsDataSource.getReceiptById(receiptId);
    if (result == null) return null;
    return ReceiptInDb.fromJson(result);
  }

  Future<List<ReceiptInDb>> searchReceiptByKeyword(String keyword) async {
    final result = await receiptsDataSource.searchReceiptByKeyword(keyword);
    final response = ListResponse<ReceiptInDb>.fromJson(
      result,
      ReceiptInDb.fromJson,
    );
    return response.data;
  }

  Future<ReceiptInDb?> updateReceiptById(
    String receiptId,
    UpdateReceipt receipt,
  ) async {
    final result = await receiptsDataSource.updateReceiptById(
      receiptId,
      receipt.toJson(),
    );
    if (result == null) return null;

    final updatedReceipt = ReceiptInDb.fromJson(result);
    final index = _receipts.indexWhere((r) => r.id == receiptId);
    if (index != -1) {
      _receipts[index] = updatedReceipt;
    }
    notifyItemUpdated(updatedReceipt);
    return updatedReceipt;
  }

  Future<ReceiptInDb?> deleteReceiptById(String receiptId) async {
    final result = await receiptsDataSource.deleteReceiptById(receiptId);
    if (result == null) return null;

    final deletedReceipt = ReceiptInDb.fromJson(result);
    _receipts.removeWhere((r) => r.id == receiptId);
    notifyItemDeleted(deletedReceipt);
    return deletedReceipt;
  }
}
