import 'package:serum_business/src/domain/query_params/cash_transaction_query_params.dart';
import 'package:serum_business/src/services/http_service.dart';
import 'package:serum_business/src/tools/http_tool.dart';

class CashTransactionsDataSource with HttpService {
  CashTransactionsDataSource._();
  static final CashTransactionsDataSource instance = CashTransactionsDataSource._();
  factory CashTransactionsDataSource() {
    return instance;
  }

  final _endpoint = "/cash-transactions";

  Future<Map<String, dynamic>> getAllCashTransactions({CashTransactionQueryParams? queryParams}) async {
    final uri = HttpTools.generateUri(_endpoint, queryParameters: queryParams?.toQueryParameters());
    final headers = HttpTools.generateAuthHeaders();
    final res = await getQuery(uri, headers: headers);
    return res;
  }
}
