import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'read_cash_registers_state.dart';

class ReadCashRegisterCubit extends Cubit<ReadCashRegisterState> {
  final CashRegistersRepository cashRegistersRepository;
  ReadCashRegisterCubit({required CashRegistersRepository cashRegistersRepository}) : cashRegistersRepository = cashRegistersRepository, super(ReadCashRegisterInitial()) {
    cashRegistersRepository.eventStream.listen(_handleRepoEvent);
  }

  void _handleRepoEvent(RepoEvent<CashRegisterInDb> event) {
    if (event is RepoItemCreated<CashRegisterInDb>) {
      markCashRegisterCreated(event.item);
    } else if (event is RepoItemUpdated<CashRegisterInDb>) {
      markCashRegisterUpdated(event.item);
    } else if (event is RepoItemDeleted<CashRegisterInDb>) {
      markCashRegisterDeleted(event.item);
    }
  }

  Future<void> getAll() async {
    final currentState = state;
    if (currentState is ReadCashRegisterSuccess) {
      emit(ReadCashRegisterRefreshing.fromSuccess(currentState));
    } else {
      emit(ReadCashRegisterLoading());
    }
    try {
      final items = await cashRegistersRepository.getAllCashRegisters();
      emit(ReadCashRegisterSuccess(items));
    } catch (e) {
      emit(ReadCashRegisterError(e.toString()));
    }
  }

  Future<void> getById(String cashRegisterId) async {
    emit(ReadCashRegisterLoading());
    try {
      final item = await cashRegistersRepository.getCashRegisterById(cashRegisterId);
      if (item != null) {
        emit(ReadCashRegisterSuccess([item]));
      } else {
        emit(ReadCashRegisterError('Not found'));
      }
    } catch (e) {
      emit(ReadCashRegisterError(e.toString()));
    }
  }

  void markCashRegisterCreated(CashRegisterInDb item) {
    final currentState = state;
    if (currentState is ReadCashRegisterSuccess) {
      final items = [item, ...currentState.items.where((u) => u.id != item.id)];
      final newItems = [...currentState.newItems, item];
      emit(ReadCashRegisterSuccess(items, newItems: newItems));
    }
  }

  void markCashRegisterUpdated(CashRegisterInDb item) {
    final currentState = state;
    if (currentState is ReadCashRegisterSuccess) {
      final items = currentState.items.map((u) => u.id == item.id ? item : u).toList();
      final updatedItems = [...currentState.updatedItems, item];
      emit(ReadCashRegisterSuccess(items, updatedItems: updatedItems));
    }
  }

  void markCashRegisterDeleted(CashRegisterInDb item) {
    final currentState = state;
    if (currentState is ReadCashRegisterSuccess) {
      final deletedItems = [...currentState.deletedItems, item];
      emit(ReadCashRegisterSuccess(currentState.items, deletedItems: deletedItems));
    }
  }
}
