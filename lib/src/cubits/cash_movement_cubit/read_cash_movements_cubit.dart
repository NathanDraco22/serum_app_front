import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'read_cash_movements_state.dart';

class ReadCashMovementCubit extends Cubit<ReadCashMovementState> {
  final CashMovementsRepository cashMovementsRepository;
  StreamSubscription<RepoEvent<CashMovementInDb>>? _subscription;

  ReadCashMovementCubit({required this.cashMovementsRepository})
      : super(ReadCashMovementInitial()) {
    _subscription =
        cashMovementsRepository.eventStream.listen(_handleRepoEvent);
  }

  Future<void> getAll([CashMovementQueryParams? queryParams]) async {
    final currentState = state;
    if (currentState is ReadCashMovementSuccess) {
      emit(ReadCashMovementRefreshing.fromSuccess(currentState));
    } else {
      emit(ReadCashMovementLoading());
    }
    try {
      final items = await cashMovementsRepository.getAllCashMovements(
          queryParams: queryParams);
      if (isClosed) return;
      emit(ReadCashMovementSuccess(items));
    } catch (error) {
      if (isClosed) return;
      emit(ReadCashMovementError(error.toString()));
    }
  }

  Future<void> getById(String cashMovementId) async {
    emit(ReadCashMovementLoading());
    try {
      final item =
          await cashMovementsRepository.getCashMovementById(cashMovementId);
      if (isClosed) return;
      if (item == null) {
        emit(const ReadCashMovementError("CashMovement not found"));
      } else {
        emit(ReadCashMovementSuccess([item]));
      }
    } catch (error) {
      if (isClosed) return;
      emit(ReadCashMovementError(error.toString()));
    }
  }

  void _handleRepoEvent(RepoEvent<CashMovementInDb> event) {
    if (isClosed) return;
    if (event is RepoItemCreated<CashMovementInDb>) {
      markMovementCreated(event.item);
    } else if (event is RepoItemUpdated<CashMovementInDb>) {
      markMovementUpdated(event.item);
    } else if (event is RepoItemDeleted<CashMovementInDb>) {
      markMovementDeleted(event.item);
    }
  }

  void markMovementCreated(CashMovementInDb item) {
    final currentState = state;
    if (currentState is ReadCashMovementSuccess) {
      final items = [
        item,
        ...currentState.items.where((u) => u.id != item.id)
      ];
      final newItems = [...currentState.newItems, item];
      emit(ReadCashMovementSuccess(items, newItems: newItems));
    }
  }

  void markMovementUpdated(CashMovementInDb item) {
    final currentState = state;
    if (currentState is ReadCashMovementSuccess) {
      final items = currentState.items
          .map((u) => u.id == item.id ? item : u)
          .toList();
      final updatedItems = [...currentState.updatedItems, item];
      emit(ReadCashMovementSuccess(items, updatedItems: updatedItems));
    }
  }

  void markMovementDeleted(CashMovementInDb item) {
    final currentState = state;
    if (currentState is ReadCashMovementSuccess) {
      final deletedItems = [...currentState.deletedItems, item];
      final remainingItems =
          currentState.items.where((u) => u.id != item.id).toList();
      emit(ReadCashMovementSuccess(remainingItems, deletedItems: deletedItems));
    }
  }

  @override
  Future<void> close() async {
    _subscription?.cancel();
    await super.close();
  }
}
