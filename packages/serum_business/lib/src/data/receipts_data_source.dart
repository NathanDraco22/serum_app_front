import '../domain/query_params/receipt_query_params.dart';
import '../services/http_service.dart';
import '../tools/http_tool.dart';

class ReceiptsDataSource with HttpService {
  ReceiptsDataSource._();
  static final ReceiptsDataSource instance = ReceiptsDataSource._();
  factory ReceiptsDataSource() {
    return instance;
  }

  final _endpoint = "/receipts";

  Future<Map<String, dynamic>> createReceipt(Map<String, dynamic> receipt) async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await postQuery(uri, receipt, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>> getAllReceipts({ReceiptQueryParams? queryParams}) async {
    final uri = HttpTools.generateUri(
      _endpoint,
      queryParameters: queryParams?.toQueryParameters(),
    );
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> getReceiptById(String receiptId) async {
    final uri = HttpTools.generateUri("$_endpoint/$receiptId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>> searchReceiptByKeyword(String keyword) async {
    final uri = HttpTools.generateUri("$_endpoint/search/$keyword");
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> updateReceiptById(
    String receiptId,
    Map<String, dynamic> receipt,
  ) async {
    final uri = HttpTools.generateUri("$_endpoint/$receiptId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await patchQuery(uri, body: receipt, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> deleteReceiptById(String receiptId) async {
    final uri = HttpTools.generateUri("$_endpoint/$receiptId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await deleteQuery(uri, headers: headers);
    return res;
  }
}
