part of 'write_quotations_cubit.dart';

sealed class WriteQuotationState {}

final class WriteQuotationInitial extends WriteQuotationState {}

final class WritingQuotation extends WriteQuotationState {}

class WriteQuotationSuccess extends WriteQuotationState {
  final QuotationInDb item;
  WriteQuotationSuccess(this.item);
}

final class QuotationCreated extends WriteQuotationSuccess {
  QuotationCreated(super.item);
}

final class QuotationUpdated extends WriteQuotationSuccess {
  QuotationUpdated(super.item);
}

final class QuotationDeleted extends WriteQuotationSuccess {
  QuotationDeleted(super.item);
}

final class WriteQuotationError extends WriteQuotationState {
  final String message;
  WriteQuotationError(this.message);
}
