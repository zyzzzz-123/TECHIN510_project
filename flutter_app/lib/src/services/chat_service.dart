import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ChatService {
  static Future<String> sendMessage(String message, {String? modelProvider}) async {
    final url = Uri.parse('$baseUrl/chat/');
    print('Sending request to: $url');
    
    final Map<String, dynamic> requestBody = {
      'message': message,
    };
    
    // 如果指定了模型提供商，添加到请求中
    if (modelProvider != null) {
      requestBody['model_provider'] = modelProvider;
    }
    
    try {
      print('Request body: ${jsonEncode(requestBody)}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      print('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['response'];
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to get AI response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception occurred: $e');
      throw Exception('Network error: $e');
    }
  }

  static Future<String> sendMessages(List<Map<String, String>> messages, {String? modelProvider}) async {
    final url = Uri.parse('$baseUrl/chat/');
    print('Sending messages to: $url');
    
    final Map<String, dynamic> requestBody = {
      'messages': messages,
    };
    
    // 如果指定了模型提供商，添加到请求中
    if (modelProvider != null) {
      requestBody['model_provider'] = modelProvider;
    }
    
    try {
      print('Request body: ${jsonEncode(requestBody)}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      print('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['response'];
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to get AI response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception occurred: $e');
      throw Exception('Network error: $e');
    }
  }
} 