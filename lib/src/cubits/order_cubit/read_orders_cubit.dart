import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'read_orders_state.dart';

class ReadOrderCubit extends Cubit<ReadOrderState> {
  final OrdersRepository ordersRepository;
  ReadOrderCubit({required OrdersRepository ordersRepository})
      : ordersRepository = ordersRepository,
        super(ReadOrderInitial()) {
    ordersRepository.eventStream.listen(_handleRepoEvent);
  }

  void _handleRepoEvent(RepoEvent<OrderInDb> event) {
    if (event is RepoItemCreated<OrderInDb>) {
      markOrderCreated(event.item);
    } else if (event is RepoItemUpdated<OrderInDb>) {
      markOrderUpdated(event.item);
    } else if (event is RepoItemDeleted<OrderInDb>) {
      markOrderDeleted(event.item);
    }
  }

  Future<void> getAll() async {
    final currentState = state;
    if (currentState is ReadOrderSuccess) {
      emit(ReadOrderRefreshing.fromSuccess(currentState));
    } else {
      emit(ReadOrderLoading());
    }
    try {
      final items = await ordersRepository.getAllOrders();
      emit(ReadOrderSuccess(items));
    } catch (e) {
      emit(ReadOrderError(e.toString()));
    }
  }

  Future<void> getById(String orderId) async {
    emit(ReadOrderLoading());
    try {
      final item = await ordersRepository.getOrderById(orderId);
      if (item != null) {
        emit(ReadOrderSuccess([item]));
      } else {
        emit(ReadOrderError('Not found'));
      }
    } catch (e) {
      emit(ReadOrderError(e.toString()));
    }
  }

  void markOrderCreated(OrderInDb item) {
    final currentState = state;
    if (currentState is ReadOrderSuccess) {
      final items = [item, ...currentState.items.where((u) => u.id != item.id)];
      final newItems = [...currentState.newItems, item];
      emit(ReadOrderSuccess(items, newItems: newItems));
    }
  }

  void markOrderUpdated(OrderInDb item) {
    final currentState = state;
    if (currentState is ReadOrderSuccess) {
      final items = currentState.items.map((u) => u.id == item.id ? item : u).toList();
      final updatedItems = [...currentState.updatedItems, item];
      emit(ReadOrderSuccess(items, updatedItems: updatedItems));
    }
  }

  void markOrderDeleted(OrderInDb item) {
    final currentState = state;
    if (currentState is ReadOrderSuccess) {
      final deletedItems = [...currentState.deletedItems, item];
      emit(ReadOrderSuccess(currentState.items, deletedItems: deletedItems));
    }
  }
}
