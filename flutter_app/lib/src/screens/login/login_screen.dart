import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config.dart';
import '../home/home_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:convert' show base64Url, utf8;
import 'register_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onLogin;
  const LoginScreen({super.key, this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isFormValid = false;
  String? _error;

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void _validateForm() {
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _isFormValid = valid;
    });
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    WidgetsBinding.instance.addPostFrameCallback((_) => _validateForm());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _isFormValid = valid;
      _error = null;
    });
    if (!valid) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final url = Uri.parse('$baseUrl/api/auth/login');
      final response = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );
      if (response.statusCode == 200) {
        // 获取用户信息
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('logged_in', true);
        
        // 解析JWT token获取用户ID
        final data = jsonDecode(response.body);
        final String token = data['access_token'];
        
        // 保存token
        await prefs.setString('access_token', token);
        
        // 从token中提取用户ID (JWT的payload部分包含sub字段，即用户ID)
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized = base64Url.normalize(payload);
            final decodedPayload = utf8.decode(base64Url.decode(normalized));
            final payloadMap = jsonDecode(decodedPayload);
            if (payloadMap['sub'] != null) {
              final userId = int.tryParse(payloadMap['sub']);
              if (userId != null) {
                await prefs.setInt('user_id', userId);
                // 同步到 ChatProvider
                final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                chatProvider.updateUser(userId, token);
              }
            }
          }
        } catch (e) {
          print('Error decoding JWT: $e');
        }
        
        if (!mounted) return;
        widget.onLogin?.call();
      } else {
        setState(() {
          _error = 'Login failed: \\${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
      });
    } finally {
    setState(() {
      _isLoading = false;
    });
    }
  }

  void _onRegisterPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: emailValidator,
                    onChanged: (_) => _validateForm(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: passwordValidator,
                    onChanged: (_) => _validateForm(),
                  ),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isFormValid && !_isLoading ? _onLoginPressed : null,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _onRegisterPressed,
                    child: const Text("Don't have an account? Register"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
