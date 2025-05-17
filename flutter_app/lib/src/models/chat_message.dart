class ChatMessage {
  final int? id;
  final String role;  // 'user' 或 'assistant'
  final String content;
  final DateTime createdAt;
  final String? modelProvider;

  ChatMessage({
    this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.modelProvider,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      role: json['role'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      modelProvider: json['model_provider'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'model_provider': modelProvider,
    };
  }
}

class GroupedChatMessages {
  final String date;
  final List<ChatMessage> messages;

  GroupedChatMessages({
    required this.date,
    required this.messages,
  });

  factory GroupedChatMessages.fromJson(Map<String, dynamic> json) {
    return GroupedChatMessages(
      date: json['date'],
      messages: (json['messages'] as List)
          .map((msg) => ChatMessage.fromJson(msg))
          .toList(),
    );
  }
} 