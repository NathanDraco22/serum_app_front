import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'read_branches_state.dart';

class ReadBranchCubit extends Cubit<ReadBranchState> {
  final BranchesRepository branchesRepository;
  StreamSubscription<RepoEvent<BranchInDb>>? _subscription;

  ReadBranchCubit({required BranchesRepository branchesRepository})
      : branchesRepository = branchesRepository,
        super(ReadBranchInitial()) {
    _subscription = branchesRepository.eventStream.listen(_handleRepoEvent);
  }

  void _handleRepoEvent(RepoEvent<BranchInDb> event) {
    if (isClosed) return;
    if (event is RepoItemCreated<BranchInDb>) {
      markBranchCreated(event.item);
    } else if (event is RepoItemUpdated<BranchInDb>) {
      markBranchUpdated(event.item);
    } else if (event is RepoItemDeleted<BranchInDb>) {
      markBranchDeleted(event.item);
    }
  }

  Future<void> getAll() async {
    final currentState = state;
    if (currentState is ReadBranchSuccess) {
      emit(ReadBranchRefreshing.fromSuccess(currentState));
    } else {
      emit(ReadBranchLoading());
    }
    try {
      final items = await branchesRepository.getAllBranches();
      if (isClosed) return;
      emit(ReadBranchSuccess(items));
    } catch (e) {
      if (isClosed) return;
      emit(ReadBranchError(e.toString()));
    }
  }

  Future<void> getById(String branchId) async {
    emit(ReadBranchLoading());
    try {
      final item = await branchesRepository.getBranchById(branchId);
      if (isClosed) return;
      if (item != null) {
        emit(ReadBranchSuccess([item]));
      } else {
        emit(ReadBranchError('Not found'));
      }
    } catch (e) {
      if (isClosed) return;
      emit(ReadBranchError(e.toString()));
    }
  }

  void markBranchCreated(BranchInDb item) {
    if (isClosed) return;
    final currentState = state;
    if (currentState is ReadBranchSuccess) {
      final items = [item, ...currentState.items.where((u) => u.id != item.id)];
      final newItems = [...currentState.newItems, item];
      emit(ReadBranchSuccess(items, newItems: newItems));
    }
  }

  void markBranchUpdated(BranchInDb item) {
    if (isClosed) return;
    final currentState = state;
    if (currentState is ReadBranchSuccess) {
      final items = currentState.items.map((u) => u.id == item.id ? item : u).toList();
      final updatedItems = [...currentState.updatedItems, item];
      emit(ReadBranchSuccess(items, updatedItems: updatedItems));
    }
  }

  void markBranchDeleted(BranchInDb item) {
    if (isClosed) return;
    final currentState = state;
    if (currentState is ReadBranchSuccess) {
      final deletedItems = [...currentState.deletedItems, item];
      emit(ReadBranchSuccess(currentState.items, deletedItems: deletedItems));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
