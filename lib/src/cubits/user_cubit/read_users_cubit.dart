import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'read_users_state.dart';

class ReadUserCubit extends Cubit<ReadUserState> {
  final UsersRepository usersRepository;
  StreamSubscription<RepoEvent<UserInDb>>? _subscription;

  ReadUserCubit({required UsersRepository usersRepository})
      : usersRepository = usersRepository,
        super(ReadUserInitial()) {
    _subscription = usersRepository.eventStream.listen(_handleRepoEvent);
  }

  void _handleRepoEvent(RepoEvent<UserInDb> event) {
    if (isClosed) return;
    if (event is RepoItemCreated<UserInDb>) {
      markUserCreated(event.item);
    } else if (event is RepoItemUpdated<UserInDb>) {
      markUserUpdated(event.item);
    } else if (event is RepoItemDeleted<UserInDb>) {
      markUserDeleted(event.item);
    }
  }

  Future<void> getAll() async {
    final currentState = state;
    if (currentState is ReadUserSuccess) {
      emit(ReadUserRefreshing.fromSuccess(currentState));
    } else {
      emit(ReadUserLoading());
    }
    try {
      final items = await usersRepository.getAllUsers();
      if (isClosed) return;
      emit(ReadUserSuccess(items));
    } catch (e) {
      if (isClosed) return;
      emit(ReadUserError(e.toString()));
    }
  }

  Future<void> getById(String userId) async {
    emit(ReadUserLoading());
    try {
      final item = await usersRepository.getUserById(userId);
      if (isClosed) return;
      if (item != null) {
        emit(ReadUserSuccess([item]));
      } else {
        emit(ReadUserError('Not found'));
      }
    } catch (e) {
      if (isClosed) return;
      emit(ReadUserError(e.toString()));
    }
  }

  void markUserCreated(UserInDb item) {
    if (isClosed) return;
    final currentState = state;
    if (currentState is ReadUserSuccess) {
      final items = [item, ...currentState.items.where((u) => u.id != item.id)];
      final newItems = [...currentState.newItems, item];
      emit(ReadUserSuccess(items, newItems: newItems));
    }
  }

  void markUserUpdated(UserInDb item) {
    if (isClosed) return;
    final currentState = state;
    if (currentState is ReadUserSuccess) {
      final items = currentState.items.map((u) => u.id == item.id ? item : u).toList();
      final updatedItems = [...currentState.updatedItems, item];
      emit(ReadUserSuccess(items, updatedItems: updatedItems));
    }
  }

  void markUserDeleted(UserInDb item) {
    if (isClosed) return;
    final currentState = state;
    if (currentState is ReadUserSuccess) {
      final deletedItems = [...currentState.deletedItems, item];
      emit(ReadUserSuccess(currentState.items, deletedItems: deletedItems));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
