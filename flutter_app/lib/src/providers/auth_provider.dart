import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  int? _userId;
  String? _username;
  String? _token;
  bool _isLoading = false;
  String? _error;

  // Getters
  int? get userId => _userId;
  String? get username => _username;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _userId != null;

  // 初始化，检查是否有已保存的登录状态
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final authData = await AuthService.checkAuth();
      if (authData != null) {
        _userId = authData['userId'];
        _username = authData['username'];
        _token = authData['token'];
      }
    } catch (e) {
      _error = 'Authentication failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 登录
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authData = await AuthService.login(username, password);
      _userId = authData['userId'];
      _username = authData['username'];
      _token = authData['token'];
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Login failed: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 注册
  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await AuthService.register(username, email, password);
      // 注册成功后自动登录
      return await login(username, password);
    } catch (e) {
      _error = 'Registration failed: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 登出
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.logout();
      _userId = null;
      _username = null;
      _token = null;
    } catch (e) {
      _error = 'Logout failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
} 