part of 'read_users_cubit.dart';

sealed class ReadUserState {}

final class ReadUserInitial extends ReadUserState {}

final class ReadUserLoading extends ReadUserState {}

class ReadUserSuccess extends ReadUserState {
  final List<UserInDb> items;
  List<UserInDb> newItems;
  List<UserInDb> updatedItems;
  List<UserInDb> deletedItems;

  ReadUserSuccess(
    this.items, {
    this.newItems = const [],
    this.updatedItems = const [],
    this.deletedItems = const [],
  });
}

final class ReadUserRefreshing extends ReadUserSuccess {
  ReadUserRefreshing(
    super.items, {
    super.newItems,
    super.updatedItems,
    super.deletedItems,
  });

  factory ReadUserRefreshing.fromSuccess(
    ReadUserSuccess success,
  ) =>
      ReadUserRefreshing(
        success.items,
        newItems: success.newItems,
        updatedItems: success.updatedItems,
        deletedItems: success.deletedItems,
      );
}

final class ReadUserError extends ReadUserState {
  final String message;
  ReadUserError(this.message);
}
