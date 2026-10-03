import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'write_roles_state.dart';

class WriteRoleCubit extends Cubit<WriteRoleState> {
  final RolesRepository _repository;

  WriteRoleCubit({required RolesRepository rolesRepository})
      : _repository = rolesRepository,
        super(WriteRoleInitial());

  Future<void> create(CreateRole createRole) async {
    emit(WritingRole());
    try {
      final item = await _repository.createRole(createRole);
      emit(RoleCreated(item));
      emit(WriteRoleInitial());
    } catch (error) {
      emit(WriteRoleError(error.toString()));
    }
  }

  Future<void> update(String roleId, UpdateRole role) async {
    emit(WritingRole());
    try {
      final item = await _repository.updateRoleById(roleId, role);
      if (item == null) {
        emit(WriteRoleError("Rol no encontrado"));
      } else {
        emit(RoleUpdated(item));
        emit(WriteRoleInitial());
      }
    } catch (error) {
      emit(WriteRoleError(error.toString()));
    }
  }

  Future<void> delete(String roleId) async {
    emit(WritingRole());
    try {
      final item = await _repository.deleteRoleById(roleId);
      if (item == null) {
        emit(WriteRoleError("Rol no encontrado"));
      } else {
        emit(RoleDeleted(item));
        emit(WriteRoleInitial());
      }
    } catch (error) {
      emit(WriteRoleError(error.toString()));
    }
  }
}
