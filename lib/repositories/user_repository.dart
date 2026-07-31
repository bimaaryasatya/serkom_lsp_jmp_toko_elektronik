import '../database/sqlite_helper.dart';
import '../models/user_model.dart';

class UserRepository {
  final SqliteHelper _sqliteHelper = SqliteHelper();

  Future<bool> register(String name, String email, String password) async {
    return _sqliteHelper.registerUser(name, email, password);
  }

  Future<UserModel?> login(String email, String password) async {
    final user = await _sqliteHelper.getUserByEmail(email);
    if (user != null && user.password == password) {
      return user;
    }
    return null;
  }

  Future<UserModel?> getUserById(int id) async {
    return _sqliteHelper.getUserById(id);
  }

  Future<bool> isFirstUser() async {
    final count = await _sqliteHelper.getUserCount();
    return count == 0;
  }

  Future<int> getUserCount() async {
    return _sqliteHelper.getUserCount();
  }

  Future<bool> updateProfile(int id, String name, String email) async {
    return _sqliteHelper.updateUserProfile(id, name, email);
  }

  Future<bool> changePassword(int id, String oldPassword, String newPassword) async {
    return _sqliteHelper.changeUserPassword(id, oldPassword, newPassword);
  }
}
