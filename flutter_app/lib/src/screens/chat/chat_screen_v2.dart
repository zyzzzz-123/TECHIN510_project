import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat_message.dart';
import '../../widgets/task_confirmation_card.dart';
import '../../providers/auth_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatScreenV2 extends StatefulWidget {
  const ChatScreenV2({super.key});

  @override
  State<ChatScreenV2> createState() => _ChatScreenV2State();
}

class _ChatScreenV2State extends State<ChatScreenV2> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showHistory = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChat();
    });
  }
  
  void _initChat() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated) {
      chatProvider.updateUser(authProvider.userId, authProvider.token);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.sendMessage(text);
    _controller.clear();
    
    // Scroll to bottom after sending message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _toggleHistory() {
    setState(() {
      _showHistory = !_showHistory;
    });
  }
  
  void _selectHistoryDate(String date) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.loadHistorySession(date);
    setState(() {
      _showHistory = false;
    });
    
    // Scroll to bottom after loading history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_showHistory ? '聊天记录' : 'AI 助手'),
            actions: [
              IconButton(
                icon: Icon(_showHistory ? Icons.chat : Icons.history),
                onPressed: _toggleHistory,
                tooltip: _showHistory ? '返回聊天' : '历史记录',
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'openai' || value == 'gemini') {
                    chatProvider.setSelectedModel(value);
                  } else if (value == 'clear') {
                    chatProvider.clearCurrentSession();
                  } else if (value == 'clear_all') {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('清空所有历史记录'),
                        content: const Text('确定要清空所有聊天记录吗？此操作不可恢复。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('取消'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              chatProvider.clearAllHistory();
                            },
                            child: const Text('确定'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  CheckedPopupMenuItem<String>(
                    value: 'openai',
                    checked: chatProvider.selectedModel == 'openai',
                    child: const Text('OpenAI (GPT)'),
                  ),
                  CheckedPopupMenuItem<String>(
                    value: 'gemini',
                    checked: chatProvider.selectedModel == 'gemini',
                    child: const Text('Google Gemini'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'clear',
                    child: Text('清空当前会话'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'clear_all',
                    child: Text('清空所有历史记录'),
                  ),
                ],
              ),
            ],
          ),
          body: _showHistory
              ? _buildHistoryView(chatProvider)
              : _buildChatView(chatProvider),
        );
      },
    );
  }
  
  Widget _buildHistoryView(ChatProvider provider) {
    if (provider.historyLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (provider.groupedHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('没有聊天记录', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return ListView.separated(
      itemCount: provider.groupedHistory.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final group = provider.groupedHistory[index];
        final date = group.date;
        final formattedDate = _formatHistoryDate(date);
        
        // 获取这个日期的最后一条消息作为预览
        final lastMessage = group.messages.isNotEmpty 
            ? group.messages.last.content 
            : '';
        final messageCount = group.messages.length;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.chat_bubble_outline, color: Colors.grey),
          ),
          title: Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$messageCount条', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          ),
          onTap: () => _selectHistoryDate(date),
        );
      },
    );
  }
  
  String _formatHistoryDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      
      if (date.year == today.year && date.month == today.month && date.day == today.day) {
        return '今天';
      } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
        return '昨天';
      } else if (date.year == now.year) {
        return DateFormat('MM月dd日').format(date);
      } else {
        return DateFormat('yyyy年MM月dd日').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }
  
  Widget _buildChatView(ChatProvider provider) {
    return Column(
      children: [
        Expanded(
          child: provider.messages.isEmpty
              ? _buildEmptyChatView()
              : _buildChatList(provider),
        ),
        if (provider.pendingTaskIntent != null)
          TaskConfirmationCard(
            intent: provider.pendingTaskIntent!,
            onConfirm: () => provider.confirmTaskAction(),
            onCancel: () => provider.cancelTaskAction(),
          ),
        if (provider.error != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.error!,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const Divider(height: 1),
        _buildInputArea(provider),
      ],
    );
  }
  
  Widget _buildEmptyChatView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '开始和AI助手对话吧！',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '你可以询问任何问题或请求帮助',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChatList(ChatProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: provider.messages.length,
      itemBuilder: (context, idx) {
        final msg = provider.messages[idx];
        
        // 确定是否显示时间：第一条消息或与上一条消息间隔超过5分钟
        bool showTime = idx == 0;
        if (idx > 0) {
          final prevMsg = provider.messages[idx - 1];
          final diff = msg.createdAt.difference(prevMsg.createdAt);
          showTime = diff.inMinutes >= 5;
        }
        
        // 检查当前消息和上一条消息是否是同一个发送者，如果是则不显示头像
        bool showAvatar = idx == 0 || provider.messages[idx - 1].role != msg.role;
        
        return Column(
          children: [
            if (showTime)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _formatMessageTime(msg.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            _buildMessageRow(msg, showAvatar),
          ],
        );
      },
    );
  }
  
  Widget _buildMessageRow(ChatMessage message, bool showAvatar) {
    final isUser = message.role == 'user';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser && showAvatar)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                backgroundColor: Colors.blue[100],
                radius: 16,
                child: const Icon(Icons.smart_toy, size: 18, color: Colors.blue),
              ),
            )
          else if (!isUser && !showAvatar)
            const SizedBox(width: 40),
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: isUser ? const Radius.circular(18) : (showAvatar ? Radius.zero : const Radius.circular(5)),
                  topRight: !isUser ? const Radius.circular(18) : (showAvatar ? Radius.zero : const Radius.circular(5)),
                  bottomLeft: const Radius.circular(18),
                  bottomRight: const Radius.circular(18),
                ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.black87 : Colors.black,
                ),
              ),
            ),
          ),
          
          if (isUser && showAvatar)
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: CircleAvatar(
                backgroundColor: Colors.blue[400],
                radius: 16,
                child: const Icon(Icons.person, size: 18, color: Colors.white),
              ),
            )
          else if (isUser && !showAvatar)
            const SizedBox(width: 40),
        ],
      ),
    );
  }
  
  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (now.difference(time).inMinutes < 60) {
      return timeago.format(time, locale: 'zh');
    } else if (messageDate == today) {
      return '今天 ${DateFormat('HH:mm').format(time)}';
    } else if (messageDate == yesterday) {
      return '昨天 ${DateFormat('HH:mm').format(time)}';
    } else if (time.year == now.year) {
      return DateFormat('MM月dd日 HH:mm').format(time);
    } else {
      return DateFormat('yyyy年MM月dd日 HH:mm').format(time);
    }
  }
  
  Widget _buildInputArea(ChatProvider provider) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        color: Colors.grey[50],
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: '输入消息...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.blue[300]!),
                  ),
                ),
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: provider.loading ? null : _sendMessage,
              mini: true,
              backgroundColor: Colors.blue[400],
              foregroundColor: Colors.white,
              elevation: 2,
              child: provider.loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
} 