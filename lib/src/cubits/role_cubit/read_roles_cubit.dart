import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'read_roles_state.dart';

class ReadRoleCubit extends Cubit<ReadRoleState> {
  final RolesRepository rolesRepository;
  StreamSubscription<RepoEvent<RoleInDb>>? _subscription;

  ReadRoleCubit({required RolesRepository rolesRepository})
      : rolesRepository = rolesRepository,
        super(ReadRoleInitial()) {
    _subscription = rolesRepository.eventStream.listen(_handleRepoEvent);
  }

  void _handleRepoEvent(RepoEvent<RoleInDb> event) {
    if (isClosed) return;
    if (event is RepoItemCreated<RoleInDb>) {
      markRoleCreated(event.item);
    } else if (event is RepoItemUpdated<RoleInDb>) {
      markRoleUpdated(event.item);
    } else if (event is RepoItemDeleted<RoleInDb>) {
      markRoleDeleted(event.item);
    }
  }

  Future<void> getAll() async {
    final currentState = state;
    if (currentState is ReadRoleSuccess) {
      emit(ReadRoleRefreshing.fromSuccess(currentState));
    } else {
      emit(ReadRoleLoading());
    }
    try {
      final items = await rolesRepository.getAllRoles();
      if (isClosed) return;
      emit(ReadRoleSuccess(items));
    } catch (error) {
      if (isClosed) return;
      emit(ReadRoleError(error.toString()));
    }
  }

  Future<void> getById(String roleId) async {
    emit(ReadRoleLoading());
    try {
      final item = await rolesRepository.getRoleById(roleId);
      if (isClosed) return;
      if (item == null) {
        emit(ReadRoleError("Rol no encontrado"));
      } else {
        emit(ReadRoleSuccess([item]));
      }
    } catch (error) {
      if (isClosed) return;
      emit(ReadRoleError(error.toString()));
    }
  }

  void markRoleCreated(RoleInDb item) {
    if (isClosed) return;
    final currentState = state;
    if (currentState is ReadRoleSuccess) {
      final items = [item, ...currentState.items.where((u) => u.id != item.id)];
      items.sort((a, b) => b.accessLevel.compareTo(a.accessLevel));
      final newItems = [...currentState.newItems, item];
      emit(ReadRoleSuccess(items, newItems: newItems));
    }
  }

  void markRoleUpdated(RoleInDb item) {
    if (isClosed) return;
    final currentState = state;
    if (currentState is ReadRoleSuccess) {
      final items = currentState.items.map((u) => u.id == item.id ? item : u).toList();
      items.sort((a, b) => b.accessLevel.compareTo(a.accessLevel));
      final updatedItems = [...currentState.updatedItems, item];
      emit(ReadRoleSuccess(items, updatedItems: updatedItems));
    }
  }

  void markRoleDeleted(RoleInDb item) {
    if (isClosed) return;
    final currentState = state;
    if (currentState is ReadRoleSuccess) {
      final items = currentState.items.where((u) => u.id != item.id).toList();
      final deletedItems = [...currentState.deletedItems, item];
      emit(ReadRoleSuccess(items, deletedItems: deletedItems));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
