import '../database/database_helper.dart';
import '../models/user_model.dart';

class UserRepository {
  final DatabaseHelper _db = DatabaseHelper();

  Future<bool> register(String name, String email, String password) async {
    var existing = await _db.getUserByEmail(email);
    if (existing != null) return false;

    await _db.insertUser(UserModel(
      name: name,
      email: email,
      password: password,
      role: 'user',
    ));
    return true;
  }

  Future<UserModel?> login(String email, String password) async {
    var user = await _db.getUserByEmail(email);
    if (user != null && user.password == password) {
      return user;
    }
    return null;
  }

  Future<UserModel?> getUserById(int id) async {
    return await _db.getUserById(id);
  }

  Future<bool> isFirstUser() async {
    var count = await _db.getUserCount();
    return count == 0;
  }
}
