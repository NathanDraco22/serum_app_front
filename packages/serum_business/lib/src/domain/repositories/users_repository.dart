import 'package:serum_business/src/domain/models/user_model/user_model.dart';
import 'package:serum_business/src/domain/responses/list_response.dart';
import 'package:serum_business/src/data/data_sources.dart';
import 'package:serum_business/src/tools/reactive_repo/reactive_repository.dart';

class UsersRepository with ReactiveRepository<UserInDb> {
  final UsersDataSource usersDataSource;

  UsersRepository(this.usersDataSource);

  List<UserInDb> _users = [];

  Future<UserInDb> createUser(CreateUser createUser) async {
    final result = await usersDataSource.createUser(createUser.toJson());
    final newUser = UserInDb.fromJson(result);
    _users = [newUser, ..._users];
    notifyItemCreated(newUser);
    return newUser;
  }

  Future<List<UserInDb>> getAllUsers() async {
    final results = await usersDataSource.getAllUsers();
    final response = ListResponse<UserInDb>.fromJson(
      results,
      UserInDb.fromJson,
    );

    _users = response.data;
    _users.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return _users;
  }

  Future<UserInDb?> getUserById(String userId) async {
    final result = await usersDataSource.getUserById(userId);
    if (result == null) return null;
    return UserInDb.fromJson(result);
  }

  Future<UserInDb?> updateUserById(
    String userId,
    UpdateUser user,
  ) async {
    final result = await usersDataSource.updateUserById(
      userId,
      user.toJson(),
    );
    if (result == null) return null;

    final updatedUser = UserInDb.fromJson(result);
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = updatedUser;
      notifyItemUpdated(updatedUser);
    }
    return updatedUser;
  }

  Future<UserInDb?> deleteUserById(String userId) async {
    final result = await usersDataSource.deleteUserById(userId);
    if (result == null) return null;

    final deletedUser = UserInDb.fromJson(result);
    _users.removeWhere((u) => u.id == userId);
    notifyItemDeleted(deletedUser);
    return deletedUser;
  }
}
