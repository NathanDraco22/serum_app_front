import 'package:serum_business/src/data/data_sources.dart';
import 'package:serum_business/src/domain/models/cash_transaction_model/cash_transaction_model.dart';
import 'package:serum_business/src/domain/query_params/cash_transaction_query_params.dart';
import 'package:serum_business/src/domain/responses/list_response.dart';

class CashTransactionsRepository {
  final CashTransactionsDataSource cashTransactionsDataSource;

  CashTransactionsRepository(this.cashTransactionsDataSource);

  List<CashTransactionInDb> _cashTransactions = [];

  Future<List<CashTransactionInDb>> getAllCashTransactions({CashTransactionQueryParams? queryParams}) async {
    final results = await cashTransactionsDataSource.getAllCashTransactions(queryParams: queryParams);
    final response = ListResponse<CashTransactionInDb>.fromJson(
      results,
      CashTransactionInDb.fromJson,
    );

    _cashTransactions = response.data;
    return _cashTransactions;
  }
}
