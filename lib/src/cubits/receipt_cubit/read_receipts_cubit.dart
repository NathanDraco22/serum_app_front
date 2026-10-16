import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'read_receipts_state.dart';

class ReadReceiptCubit extends Cubit<ReadReceiptState> {
  final ReceiptsRepository receiptsRepository;
  StreamSubscription<RepoEvent<ReceiptInDb>>? _subscription;

  ReadReceiptCubit({required this.receiptsRepository})
      : super(ReadReceiptInitial()) {
    _subscription = receiptsRepository.eventStream.listen(_handleRepoEvent);
  }

  Future<void> getAll([ReceiptQueryParams? queryParams]) async {
    final currentState = state;
    if (currentState is ReadReceiptSuccess) {
      emit(ReadReceiptRefreshing.fromSuccess(currentState));
    } else {
      emit(ReadReceiptLoading());
    }
    try {
      final items =
          await receiptsRepository.getAllReceipts(queryParams: queryParams);
      if (isClosed) return;
      emit(ReadReceiptSuccess(items));
    } catch (error) {
      if (isClosed) return;
      emit(ReadReceiptError(error.toString()));
    }
  }

  Future<void> getById(String receiptId) async {
    emit(ReadReceiptLoading());
    try {
      final item = await receiptsRepository.getReceiptById(receiptId);
      if (isClosed) return;
      if (item == null) {
        emit(ReadReceiptError("Receipt not found"));
      } else {
        emit(ReadReceiptSuccess([item]));
      }
    } catch (error) {
      if (isClosed) return;
      emit(ReadReceiptError(error.toString()));
    }
  }

  void _handleRepoEvent(RepoEvent<ReceiptInDb> event) {
    if (isClosed) return;
    if (event is RepoItemCreated<ReceiptInDb>) {
      markReceiptCreated(event.item);
    } else if (event is RepoItemUpdated<ReceiptInDb>) {
      markReceiptUpdated(event.item);
    } else if (event is RepoItemDeleted<ReceiptInDb>) {
      markReceiptDeleted(event.item);
    }
  }

  void markReceiptCreated(ReceiptInDb item) {
    final currentState = state;
    if (currentState is ReadReceiptSuccess) {
      final items = [
        item,
        ...currentState.items.where((u) => u.id != item.id)
      ];
      final newItems = [...currentState.newItems, item];
      emit(ReadReceiptSuccess(items, newItems: newItems));
    }
  }

  void markReceiptUpdated(ReceiptInDb item) {
    final currentState = state;
    if (currentState is ReadReceiptSuccess) {
      final items = currentState.items
          .map((u) => u.id == item.id ? item : u)
          .toList();
      final updatedItems = [...currentState.updatedItems, item];
      emit(ReadReceiptSuccess(items, updatedItems: updatedItems));
    }
  }

  void markReceiptDeleted(ReceiptInDb item) {
    final currentState = state;
    if (currentState is ReadReceiptSuccess) {
      final deletedItems = [...currentState.deletedItems, item];
      final remainingItems =
          currentState.items.where((u) => u.id != item.id).toList();
      emit(ReadReceiptSuccess(remainingItems, deletedItems: deletedItems));
    }
  }

  @override
  Future<void> close() async {
    _subscription?.cancel();
    await super.close();
  }
}
