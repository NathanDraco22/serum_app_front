import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:serum_business/serum_business.dart';

part 'write_users_state.dart';

class WriteUserCubit extends Cubit<WriteUserState> {
  final UsersRepository usersRepository;

  WriteUserCubit({required this.usersRepository})
      : super(WriteUserInitial());

  Future<void> create(CreateUser createUser) async {
    emit(WritingUser());
    try {
      final item = await usersRepository.createUser(createUser);
      emit(UserCreated(item));
    } catch (e) {
      emit(WriteUserError(e.toString()));
    }
  }

  Future<void> update(String userId, UpdateUser user) async {
    emit(WritingUser());
    try {
      final item = await usersRepository.updateUserById(userId, user);
      if (item != null) {
        emit(UserUpdated(item));
      } else {
        emit(WriteUserError('Not found'));
      }
    } catch (e) {
      emit(WriteUserError(e.toString()));
    }
  }

  Future<void> delete(String userId) async {
    emit(WritingUser());
    try {
      final item = await usersRepository.deleteUserById(userId);
      if (item != null) {
        emit(UserDeleted(item));
      } else {
        emit(WriteUserError('Not found'));
      }
    } catch (e) {
      emit(WriteUserError(e.toString()));
    }
  }
}
