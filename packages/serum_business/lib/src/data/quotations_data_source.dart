import 'package:serum_business/src/services/http_service.dart';
import 'package:serum_business/src/tools/http_tool.dart';

class QuotationsDataSource with HttpService {
  QuotationsDataSource._();
  static final QuotationsDataSource instance = QuotationsDataSource._();
  factory QuotationsDataSource() {
    return instance;
  }

  final _endpoint = "/quotations";

  Future<Map<String, dynamic>> createQuotation(Map<String, dynamic> quotation) async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await postQuery(uri, quotation, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>> getAllQuotations() async {
    final uri = HttpTools.generateUri(_endpoint);
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> getQuotationById(String quotationId) async {
    final uri = HttpTools.generateUri("$_endpoint/$quotationId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> updateQuotationById(
    String quotationId,
    Map<String, dynamic> quotation,
  ) async {
    final uri = HttpTools.generateUri("$_endpoint/$quotationId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await patchQuery(uri, body: quotation, headers: headers);
    return res;
  }

  Future<Map<String, dynamic>?> deleteQuotationById(String quotationId) async {
    final uri = HttpTools.generateUri("$_endpoint/$quotationId");
    final headers = HttpTools.generateAuthHeaders();
    final res = await deleteQuery(uri, headers: headers);
    return res;
  }
}
