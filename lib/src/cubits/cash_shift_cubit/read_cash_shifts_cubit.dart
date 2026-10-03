import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'read_cash_shifts_state.dart';

class ReadCashShiftCubit extends Cubit<ReadCashShiftState> {
  ReadCashShiftCubit({required CashShiftsRepository cashShiftsRepository})
      : _repository = cashShiftsRepository,
        super(ReadCashShiftInitial()) {
    _subscription = _repository.eventStream.listen(_handleRepoEvent);
  }

  final CashShiftsRepository _repository;
  StreamSubscription<RepoEvent<CashShiftInDb>>? _subscription;

  Future<void> getAll({
    String? branchId,
    String? userId,
    String? status,
  }) async {
    final currentState = state;
    if (currentState is ReadCashShiftSuccess) {
      emit(ReadCashShiftRefreshing.fromSuccess(currentState));
    } else {
      emit(ReadCashShiftLoading());
    }
    try {
      final items = await _repository.getAllCashShifts(
        branchId: branchId,
        userId: userId,
        status: status,
      );
      emit(ReadCashShiftSuccess(items));
    } catch (error) {
      emit(ReadCashShiftError(error.toString()));
    }
  }

  Future<void> getById(String shiftId) async {
    emit(ReadCashShiftLoading());
    try {
      final item = await _repository.getCashShiftById(shiftId);
      if (item == null) {
        emit(ReadCashShiftError("CashShift not found"));
      } else {
        emit(ReadCashShiftSuccess([item]));
      }
    } catch (error) {
      emit(ReadCashShiftError(error.toString()));
    }
  }

  void _handleRepoEvent(RepoEvent<CashShiftInDb> event) {
    switch (event) {
      case RepoItemCreated(:final item):
        markCashShiftCreated(item);
      case RepoItemUpdated(:final item):
        markCashShiftUpdated(item);
      case RepoItemDeleted(:final item):
        markCashShiftDeleted(item);
    }
  }

  void markCashShiftCreated(CashShiftInDb item) {
    final currentState = state;
    if (currentState is ReadCashShiftSuccess) {
      final items = [
        item,
        ...currentState.items.where((u) => u.id != item.id)
      ];
      final newItems = [...currentState.newItems, item];
      emit(ReadCashShiftSuccess(items, newItems: newItems));
    }
  }

  void markCashShiftUpdated(CashShiftInDb item) {
    final currentState = state;
    if (currentState is ReadCashShiftSuccess) {
      final items =
          currentState.items.map((u) => u.id == item.id ? item : u).toList();
      final updatedItems = [...currentState.updatedItems, item];
      emit(ReadCashShiftSuccess(items, updatedItems: updatedItems));
    }
  }

  void markCashShiftDeleted(CashShiftInDb item) {
    final currentState = state;
    if (currentState is ReadCashShiftSuccess) {
      final deletedItems = [...currentState.deletedItems, item];
      emit(ReadCashShiftSuccess(currentState.items, deletedItems: deletedItems));
    }
  }

  @override
  Future<void> close() async {
    _subscription?.cancel();
    await super.close();
  }
}
