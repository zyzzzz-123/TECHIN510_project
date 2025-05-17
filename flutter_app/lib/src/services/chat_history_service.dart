import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/chat_message.dart';

class ChatHistoryService {
  static Future<List<GroupedChatMessages>> getChatHistory({
    String? authToken,
    int days = 7,
    int limit = 200,
  }) async {
    if (authToken == null) {
      return [];
    }
    
    final url = Uri.parse('$baseUrl/chat-history/?days=$days&limit=$limit');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((group) => GroupedChatMessages.fromJson(group)).toList();
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to get chat history: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception occurred: $e');
      throw Exception('Network error: $e');
    }
  }
  
  static Future<void> deleteMessage(int messageId, String authToken) async {
    final url = Uri.parse('$baseUrl/chat-history/$messageId');
    
    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );
      
      if (response.statusCode != 204) {
        print('Error response: ${response.body}');
        throw Exception('Failed to delete message: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception occurred: $e');
      throw Exception('Network error: $e');
    }
  }
  
  static Future<void> clearHistory(String authToken) async {
    final url = Uri.parse('$baseUrl/chat-history/');
    
    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );
      
      if (response.statusCode != 204) {
        print('Error response: ${response.body}');
        throw Exception('Failed to clear history: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception occurred: $e');
      throw Exception('Network error: $e');
    }
  }
} 