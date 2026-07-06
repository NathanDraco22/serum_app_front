import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'read_quotations_state.dart';

class ReadQuotationCubit extends Cubit<ReadQuotationState> {
  final QuotationsRepository quotationsRepository;
  ReadQuotationCubit({required QuotationsRepository quotationsRepository})
      : quotationsRepository = quotationsRepository,
        super(ReadQuotationInitial()) {
    quotationsRepository.eventStream.listen(_handleRepoEvent);
  }

  void _handleRepoEvent(RepoEvent<QuotationInDb> event) {
    if (event is RepoItemCreated<QuotationInDb>) {
      markQuotationCreated(event.item);
    } else if (event is RepoItemUpdated<QuotationInDb>) {
      markQuotationUpdated(event.item);
    } else if (event is RepoItemDeleted<QuotationInDb>) {
      markQuotationDeleted(event.item);
    }
  }

  Future<void> getAll() async {
    final currentState = state;
    if (currentState is ReadQuotationSuccess) {
      emit(ReadQuotationRefreshing.fromSuccess(currentState));
    } else {
      emit(ReadQuotationLoading());
    }
    try {
      final items = await quotationsRepository.getAllQuotations();
      emit(ReadQuotationSuccess(items));
    } catch (e) {
      emit(ReadQuotationError(e.toString()));
    }
  }

  Future<void> getById(String quotationId) async {
    emit(ReadQuotationLoading());
    try {
      final item = await quotationsRepository.getQuotationById(quotationId);
      if (item != null) {
        emit(ReadQuotationSuccess([item]));
      } else {
        emit(ReadQuotationError('Not found'));
      }
    } catch (e) {
      emit(ReadQuotationError(e.toString()));
    }
  }

  void markQuotationCreated(QuotationInDb item) {
    final currentState = state;
    if (currentState is ReadQuotationSuccess) {
      final items = [item, ...currentState.items.where((u) => u.id != item.id)];
      final newItems = [...currentState.newItems, item];
      emit(ReadQuotationSuccess(items, newItems: newItems));
    }
  }

  void markQuotationUpdated(QuotationInDb item) {
    final currentState = state;
    if (currentState is ReadQuotationSuccess) {
      final items = currentState.items.map((u) => u.id == item.id ? item : u).toList();
      final updatedItems = [...currentState.updatedItems, item];
      emit(ReadQuotationSuccess(items, updatedItems: updatedItems));
    }
  }

  void markQuotationDeleted(QuotationInDb item) {
    final currentState = state;
    if (currentState is ReadQuotationSuccess) {
      final deletedItems = [...currentState.deletedItems, item];
      emit(ReadQuotationSuccess(currentState.items, deletedItems: deletedItems));
    }
  }
}
