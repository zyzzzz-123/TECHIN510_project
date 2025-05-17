import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';

  // 登录
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/token');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': username,
        'password': password,
      },
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      final userId = data['user_id'];
      
      // 保存到本地存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setInt(_userIdKey, userId);
      await prefs.setString(_usernameKey, username);
      
      return {
        'token': token,
        'userId': userId,
        'username': username,
      };
    } else {
      throw Exception('Failed to login: ${response.statusCode} - ${response.body}');
    }
  }
  
  // 注册
  static Future<void> register(String username, String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/register');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode != 201) {
      throw Exception('Failed to register: ${response.statusCode} - ${response.body}');
    }
  }
  
  // 登出
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
  }
  
  // 检查是否已登录
  static Future<Map<String, dynamic>?> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userId = prefs.getInt(_userIdKey);
    final username = prefs.getString(_usernameKey);
    
    if (token != null && userId != null && username != null) {
      return {
        'token': token,
        'userId': userId,
        'username': username,
      };
    }
    
    return null;
  }
  
  // 获取token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  // 获取用户ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }
} 