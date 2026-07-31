import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/sqlite_helper.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class AuthProvider extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  final SqliteHelper _sqliteHelper = SqliteHelper();

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
      // Muat sesi user dari SQLite lokal (mode offline penuh tanpa server)
      UserModel? cachedUser = await _sqliteHelper.getCachedUser();
      if (cachedUser != null) {
        _user = cachedUser;
        notifyListeners();
      }
    } catch (e) {
      // silent fail on startup
    }
  }

  Future<void> refreshUser() async {
    final current = _user;
    if (current?.id == null) return;

    final fresh = await _userRepository.getUserById(current!.id!);
    if (fresh != null) {
      _user = fresh;
      await _sqliteHelper.saveSession(
        userId: fresh.id!,
        token: 'token_${fresh.id}_${DateTime.now().millisecondsSinceEpoch}',
        name: fresh.name,
        email: fresh.email,
        role: fresh.role,
      );
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final db = await _sqliteHelper.database;
      if (db == null) {
        final detail = SqliteHelper.lastOpenError;
        _error = detail != null && detail.isNotEmpty
            ? 'Gagal membuka database lokal: $detail'
            : 'Gagal membuka database lokal. Hapus file tiptronic_local.db lalu jalankan ulang.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      var user = await _userRepository.login(email, password);
      if (user != null) {
        _user = user;

        // Simpan sesi dan token login ke SQLite lokal
        await _sqliteHelper.saveSession(
          userId: user.id!,
          token: 'token_${user.id}_${DateTime.now().millisecondsSinceEpoch}',
          name: user.name,
          email: user.email,
          role: user.role,
        );

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

          await _sqliteHelper.saveSession(
            userId: user.id!,
            token: 'token_${user.id}_${DateTime.now().millisecondsSinceEpoch}',
            name: user.name,
            email: user.email,
            role: user.role,
          );

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
    await _sqliteHelper.clearSession();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    notifyListeners();
  }
}

