part of 'read_quotations_cubit.dart';

sealed class ReadQuotationState {}

final class ReadQuotationInitial extends ReadQuotationState {}

final class ReadQuotationLoading extends ReadQuotationState {}

class ReadQuotationSuccess extends ReadQuotationState {
  final List<QuotationInDb> items;
  List<QuotationInDb> newItems;
  List<QuotationInDb> updatedItems;
  List<QuotationInDb> deletedItems;

  ReadQuotationSuccess(
    this.items, {
    this.newItems = const [],
    this.updatedItems = const [],
    this.deletedItems = const [],
  });
}

final class ReadQuotationRefreshing extends ReadQuotationSuccess {
  ReadQuotationRefreshing(
    super.items, {
    super.newItems,
    super.updatedItems,
    super.deletedItems,
  });

  factory ReadQuotationRefreshing.fromSuccess(
    ReadQuotationSuccess success,
  ) =>
      ReadQuotationRefreshing(
        success.items,
        newItems: success.newItems,
        updatedItems: success.updatedItems,
        deletedItems: success.deletedItems,
      );
}

final class ReadQuotationError extends ReadQuotationState {
  final String message;
  ReadQuotationError(this.message);
}
