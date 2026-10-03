part of 'write_roles_cubit.dart';

sealed class WriteRoleState {}

final class WriteRoleInitial extends WriteRoleState {}

final class WritingRole extends WriteRoleState {}

class WriteRoleSuccess extends WriteRoleState {
  final RoleInDb item;
  WriteRoleSuccess(this.item);
}

final class RoleCreated extends WriteRoleSuccess {
  RoleCreated(super.item);
}

final class RoleUpdated extends WriteRoleSuccess {
  RoleUpdated(super.item);
}

final class RoleDeleted extends WriteRoleSuccess {
  RoleDeleted(super.item);
}

final class WriteRoleError extends WriteRoleState {
  final String message;
  WriteRoleError(this.message);
}
