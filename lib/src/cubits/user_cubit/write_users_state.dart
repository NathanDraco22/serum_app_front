part of 'write_users_cubit.dart';

sealed class WriteUserState {}

final class WriteUserInitial extends WriteUserState {}

final class WritingUser extends WriteUserState {}

class WriteUserSuccess extends WriteUserState {
  final UserInDb item;
  WriteUserSuccess(this.item);
}

final class UserCreated extends WriteUserSuccess {
  UserCreated(super.item);
}

final class UserUpdated extends WriteUserSuccess {
  UserUpdated(super.item);
}

final class UserDeleted extends WriteUserSuccess {
  UserDeleted(super.item);
}

final class WriteUserError extends WriteUserState {
  final String message;
  WriteUserError(this.message);
}
