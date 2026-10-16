part of 'write_receipts_cubit.dart';

sealed class WriteReceiptState {}

final class WriteReceiptInitial extends WriteReceiptState {}

final class WritingReceipt extends WriteReceiptState {}

class WriteReceiptSuccess extends WriteReceiptState {
  final ReceiptInDb item;
  WriteReceiptSuccess(this.item);
}

final class ReceiptCreated extends WriteReceiptSuccess {
  ReceiptCreated(super.item);
}

final class ReceiptUpdated extends WriteReceiptSuccess {
  ReceiptUpdated(super.item);
}

final class ReceiptDeleted extends WriteReceiptSuccess {
  ReceiptDeleted(super.item);
}

final class WriteReceiptError extends WriteReceiptState {
  final String message;
  WriteReceiptError(this.message);
}
