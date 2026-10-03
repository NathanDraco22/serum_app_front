import 'package:serum_business/src/data/roles_data_source.dart';
import 'package:serum_business/src/domain/models/role_model/role_model.dart';
import 'package:serum_business/src/domain/responses/list_response.dart';
import 'package:serum_business/src/tools/reactive_repo/reactive_repository.dart';

class RolesRepository with ReactiveRepository<RoleInDb> {
  final RolesDataSource rolesDataSource;

  RolesRepository(this.rolesDataSource);

  List<RoleInDb> _roles = [];

  List<RoleInDb> get roles => _roles;

  Future<RoleInDb> createRole(CreateRole createRole) async {
    final result = await rolesDataSource.createRole(createRole.toJson());
    final newRole = RoleInDb.fromJson(result);
    _roles = [newRole, ..._roles];
    notifyItemCreated(newRole);
    return newRole;
  }

  Future<List<RoleInDb>> getAllRoles() async {
    final results = await rolesDataSource.getAllRoles();
    final response = ListResponse<RoleInDb>.fromJson(
      results,
      RoleInDb.fromJson,
    );

    _roles = response.data;
    _roles.sort(
      (a, b) => b.accessLevel.compareTo(a.accessLevel),
    );
    return _roles;
  }

  Future<RoleInDb?> getRoleById(String roleId) async {
    final result = await rolesDataSource.getRoleById(roleId);
    if (result == null) return null;
    return RoleInDb.fromJson(result);
  }

  Future<List<RoleInDb>> searchRoleByKeyword(String keyword) async {
    final result = await rolesDataSource.searchRoleByKeyword(keyword);
    final response = ListResponse<RoleInDb>.fromJson(
      result,
      RoleInDb.fromJson,
    );
    return response.data;
  }

  Future<RoleInDb?> updateRoleById(
    String roleId,
    UpdateRole role,
  ) async {
    final result = await rolesDataSource.updateRoleById(
      roleId,
      role.toJson(),
    );
    if (result == null) return null;

    final updatedRole = RoleInDb.fromJson(result);
    final index = _roles.indexWhere((u) => u.id == roleId);
    if (index != -1) {
      _roles[index] = updatedRole;
      notifyItemUpdated(updatedRole);
    }
    return updatedRole;
  }

  Future<RoleInDb?> deleteRoleById(String roleId) async {
    final result = await rolesDataSource.deleteRoleById(roleId);
    if (result == null) return null;

    final deletedRole = RoleInDb.fromJson(result);
    _roles.removeWhere((u) => u.id == roleId);
    notifyItemDeleted(deletedRole);
    return deletedRole;
  }
}
