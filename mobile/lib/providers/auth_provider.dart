// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../core/constants.dart';

class AuthProvider extends ChangeNotifier {
  final _api = ApiService();

  User?  _user;
  bool   _loading = false;
  String? _error;

  User?  get user    => _user;
  bool   get loading => _loading;
  String? get error  => _error;
  bool   get isLoggedIn => _user != null;
  bool   get isCoach => _user?.isCoach ?? false;

  // Load stored session on app start
  Future<void> initialize() async {
    // Auto-logout when any API call returns 401 (expired token)
    _api.onUnauthorized = () {
      if (_user != null) logout();
    };

    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? true;
    if (!rememberMe) {
      await _api.clearToken();
      await prefs.remove(AppConstants.userKey);
      return;
    }
    await _api.loadToken();
    final stored = prefs.getString(AppConstants.userKey);
    if (stored != null) {
      try {
        _user = User.fromJson(jsonDecode(stored));
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<bool> login(String username, String password, {bool rememberMe = true}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.post('/auth/login', {
        'username': username,
        'password': password,
      });

      await _api.saveToken(res['token']);
      _user = User.fromJson(res['user']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userKey, jsonEncode(res['user']));
      await prefs.setBool('remember_me', rememberMe);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.post('/auth/register', {
        'username': username,
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role,
      });

      await _api.saveToken(res['token']);
      _user = User.fromJson(res['user']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userKey, jsonEncode(res['user']));
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userKey);
    await prefs.remove('remember_me');
    _user = null;
    notifyListeners();
  }
}
