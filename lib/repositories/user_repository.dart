import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/constants.dart';
import '../models/user_model.dart';

class UserRepository {
  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'role': 'user',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          final userData = Map<String, dynamic>.from(data['user']);
          userData['password'] = password; // sertakan password untuk memuaskan model jika dibutuhkan
          return UserModel.fromMap(userData);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> getUserById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/users/$id'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          final userData = Map<String, dynamic>.from(data['user']);
          userData['password'] = '';
          return UserModel.fromMap(userData);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isFirstUser() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/users/count'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final count = data['count'] ?? 0;
        return count == 0;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
