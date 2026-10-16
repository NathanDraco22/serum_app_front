import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'write_receipts_state.dart';

class WriteReceiptCubit extends Cubit<WriteReceiptState> {
  final ReceiptsRepository receiptsRepository;

  WriteReceiptCubit({required this.receiptsRepository})
      : super(WriteReceiptInitial());

  Future<void> create(CreateReceipt createReceipt) async {
    emit(WritingReceipt());
    try {
      final item = await receiptsRepository.createReceipt(createReceipt);
      emit(ReceiptCreated(item));
      emit(WriteReceiptInitial());
    } catch (error) {
      emit(WriteReceiptError(error.toString()));
    }
  }

  Future<void> update(String receiptId, UpdateReceipt receipt) async {
    emit(WritingReceipt());
    try {
      final item = await receiptsRepository.updateReceiptById(receiptId, receipt);
      if (item == null) {
        emit(WriteReceiptError("Receipt not found"));
      } else {
        emit(ReceiptUpdated(item));
        emit(WriteReceiptInitial());
      }
    } catch (error) {
      emit(WriteReceiptError(error.toString()));
    }
  }

  Future<void> delete(String receiptId) async {
    emit(WritingReceipt());
    try {
      final item = await receiptsRepository.deleteReceiptById(receiptId);
      if (item == null) {
        emit(WriteReceiptError("Receipt not found"));
      } else {
        emit(ReceiptDeleted(item));
        emit(WriteReceiptInitial());
      }
    } catch (error) {
      emit(WriteReceiptError(error.toString()));
    }
  }
}
