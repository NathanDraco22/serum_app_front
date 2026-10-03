part of 'read_roles_cubit.dart';

sealed class ReadRoleState {}

final class ReadRoleInitial extends ReadRoleState {}

final class ReadRoleLoading extends ReadRoleState {}

class ReadRoleSuccess extends ReadRoleState {
  final List<RoleInDb> items;
  List<RoleInDb> newItems;
  List<RoleInDb> updatedItems;
  List<RoleInDb> deletedItems;

  ReadRoleSuccess(
    this.items, {
    this.newItems = const [],
    this.updatedItems = const [],
    this.deletedItems = const [],
  });
}

final class ReadRoleRefreshing extends ReadRoleSuccess {
  ReadRoleRefreshing(
    super.items, {
    super.newItems,
    super.updatedItems,
    super.deletedItems,
  });

  factory ReadRoleRefreshing.fromSuccess(
    ReadRoleSuccess success,
  ) =>
      ReadRoleRefreshing(
        success.items,
        newItems: success.newItems,
        updatedItems: success.updatedItems,
        deletedItems: success.deletedItems,
      );
}

final class ReadRoleError extends ReadRoleState {
  final String message;
  ReadRoleError(this.message);
}
