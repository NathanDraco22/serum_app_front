import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'write_quotations_state.dart';

class WriteQuotationCubit extends Cubit<WriteQuotationState> {
  final QuotationsRepository quotationsRepository;

  WriteQuotationCubit({required this.quotationsRepository})
      : super(WriteQuotationInitial());

  Future<void> create(CreateQuotation createQuotation) async {
    emit(WritingQuotation());
    try {
      final item = await quotationsRepository.createQuotation(createQuotation);
      emit(QuotationCreated(item));
    } catch (e) {
      emit(WriteQuotationError(e.toString()));
    }
  }

  Future<void> update(String quotationId, UpdateQuotation quotation) async {
    emit(WritingQuotation());
    try {
      final item = await quotationsRepository.updateQuotationById(quotationId, quotation);
      if (item != null) {
        emit(QuotationUpdated(item));
      } else {
        emit(WriteQuotationError('Not found'));
      }
    } catch (e) {
      emit(WriteQuotationError(e.toString()));
    }
  }

  Future<void> delete(String quotationId) async {
    emit(WritingQuotation());
    try {
      final item = await quotationsRepository.deleteQuotationById(quotationId);
      if (item != null) {
        emit(QuotationDeleted(item));
      } else {
        emit(WriteQuotationError('Not found'));
      }
    } catch (e) {
      emit(WriteQuotationError(e.toString()));
    }
  }
}
