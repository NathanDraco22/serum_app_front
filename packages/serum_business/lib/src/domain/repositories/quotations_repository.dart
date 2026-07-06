import 'package:serum_business/src/domain/models/quotation_model/quotation_model.dart';
import 'package:serum_business/src/domain/responses/list_response.dart';
import 'package:serum_business/src/data/data_sources.dart';
import 'package:serum_business/src/tools/reactive_repo/reactive_repository.dart';

class QuotationsRepository with ReactiveRepository<QuotationInDb> {
  final QuotationsDataSource quotationsDataSource;

  QuotationsRepository(this.quotationsDataSource);

  List<QuotationInDb> _quotations = [];

  Future<QuotationInDb> createQuotation(CreateQuotation createQuotation) async {
    final result = await quotationsDataSource.createQuotation(createQuotation.toJson());
    final newQuotation = QuotationInDb.fromJson(result);
    _quotations = [newQuotation, ..._quotations];
    notifyItemCreated(newQuotation);
    return newQuotation;
  }

  Future<List<QuotationInDb>> getAllQuotations() async {
    final results = await quotationsDataSource.getAllQuotations();
    final response = ListResponse<QuotationInDb>.fromJson(
      results,
      QuotationInDb.fromJson,
    );

    _quotations = response.data;
    return _quotations;
  }

  Future<QuotationInDb?> getQuotationById(String quotationId) async {
    final result = await quotationsDataSource.getQuotationById(quotationId);
    if (result == null) return null;
    return QuotationInDb.fromJson(result);
  }

  Future<QuotationInDb?> updateQuotationById(
    String quotationId,
    UpdateQuotation quotation,
  ) async {
    final result = await quotationsDataSource.updateQuotationById(
      quotationId,
      quotation.toJson(),
    );
    if (result == null) return null;

    final updatedQuotation = QuotationInDb.fromJson(result);
    final index = _quotations.indexWhere((u) => u.id == quotationId);
    if (index != -1) {
      _quotations[index] = updatedQuotation;
      notifyItemUpdated(updatedQuotation);
    }
    return updatedQuotation;
  }

  Future<QuotationInDb?> deleteQuotationById(String quotationId) async {
    final result = await quotationsDataSource.deleteQuotationById(quotationId);
    if (result == null) return null;

    final deletedQuotation = QuotationInDb.fromJson(result);
    _quotations.removeWhere((u) => u.id == quotationId);
    notifyItemDeleted(deletedQuotation);
    return deletedQuotation;
  }
}
