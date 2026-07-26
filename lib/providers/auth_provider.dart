import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class AuthProvider extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.role == 'admin';

  Future<void> checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('userId');
      if (userId != null) {
        _user = await _userRepository.getUserById(userId);
        notifyListeners();
      }
    } catch (e) {
      // silent fail on startup
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      var user = await _userRepository.login(email, password);
      if (user != null) {
        _user = user;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', user.id!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Email atau password salah';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Terjadi kesalahan: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool success = await _userRepository.register(name, email, password);
      if (success) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Email sudah terdaftar';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Terjadi kesalahan: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerAdmin(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool isFirst = await _userRepository.isFirstUser();
      var existing = await _userRepository.login(email, password);

      if (isFirst || existing == null) {
        await _userRepository.register(name, email, password);
        var user = await _userRepository.login(email, password);
        if (user != null) {
          _user = user;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('userId', user.id!);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _error = 'Gagal mendaftarkan admin';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Terjadi kesalahan: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    notifyListeners();
  }
}
