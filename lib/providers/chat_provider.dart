import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/chat_message_model.dart';
import '../services/chat_service.dart';
import '../services/local_storage_service.dart';
import '../services/message_parser_service.dart';
import '../utils/logger.dart';

class ChatProvider with ChangeNotifier {
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _deleteThreadsLoading = false;
  final Set<String> _activeApiCalls = {};
  String? _pendingApiCallId;
  Timer? _typingTimer;
  Timer? _safetyTimeout;

  // Default welcome message
  static ChatMessage _getDefaultWelcomeMessage() => ChatMessage(
    id: 'welcome_message',
    text: 'كيف يمكنني مساعدتك اليوم؟',
    senderType: SenderType.ai,
    timestamp: DateTime.now(),
    status: MessageStatus.read,
    parsedParts: [
      MessagePart(
        text: 'كيف يمكنني مساعدتك اليوم؟',
        isLink: false,
        isBold: false,
      ),
    ],
    messageType: MessageType.text,
  );

  // Getters
  List<ChatMessage> get messages => _messages.isEmpty ? [_getDefaultWelcomeMessage()] : _messages;
  bool get isTyping => _isTyping;
  bool get deleteThreadsLoading => _deleteThreadsLoading;
  Set<String> get activeApiCalls => _activeApiCalls;
  String? get pendingApiCallId => _pendingApiCallId;

  ChatProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    try {
      // Load messages from local storage
      await loadMessages();
      
      // Check for pending API calls and recover
      await _recoverPendingApiCall();
      
      // Perform data migration if needed
      await LocalStorageService.migrateData();
      
      Logger.log('ChatProvider: Initialized successfully');
    } catch (e) {
      Logger.log('ChatProvider: Error during initialization - $e');
    }
  }

  // Load messages from local storage
  Future<void> loadMessages() async {
    try {
      _messages = await LocalStorageService.loadMessages();
      notifyListeners();
      Logger.log('ChatProvider: Loaded ${_messages.length} messages');
    } catch (e) {
      Logger.log('ChatProvider: Error loading messages - $e');
    }
  }

  // Save messages to local storage
  Future<void> _saveMessages() async {
    try {
      await LocalStorageService.saveMessages(_messages);
    } catch (e) {
      Logger.log('ChatProvider: Error saving messages - $e');
    }
  }

  // Send a message
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final messageId = _generateMessageId();
    
    // Check for duplicate API calls
    if (_activeApiCalls.contains(messageId)) {
      Logger.log('ChatProvider: Duplicate API call prevented for $messageId');
      return;
    }

    // Additional check to prevent duplicate messages with same content
    final trimmedText = text.trim();
    final lastMessage = _messages.isNotEmpty ? _messages.last : null;
    if (lastMessage != null && 
        lastMessage.text == trimmedText && 
        lastMessage.senderType == SenderType.user &&
        DateTime.now().difference(lastMessage.timestamp).inSeconds < 2) {
      Logger.log('ChatProvider: Duplicate message prevented - same text within 2 seconds');
      return;
    }

    try {
      // Create user message
      final userMessage = ChatMessage(
        id: messageId,
        text: text.trim(),
        senderType: SenderType.user,
        timestamp: DateTime.now(),
        parsedParts: MessageParserService.parseMessage(text.trim()),
      );

      // Add user message to list
      _messages.add(userMessage);
      // Keep only the last 100 messages
      if (_messages.length > 100) {
        _messages = _messages.sublist(_messages.length - 100);
      }
      notifyListeners();
      await _saveMessages();

      // Save pending API call for recovery
      _pendingApiCallId = messageId;
      _activeApiCalls.add(messageId);
      await LocalStorageService.savePendingApiCall(messageId);

      // Show typing indicator with delay
      await Future.delayed(const Duration(milliseconds: 1500));
      _showTypingIndicator();

      // Immediately set last user message as delivered (show blue ticks)
      final lastUserMsgIndex = _messages.lastIndexWhere((msg) => msg.senderType == SenderType.user);
      if (lastUserMsgIndex != -1) {
        _messages[lastUserMsgIndex] = _messages[lastUserMsgIndex].copyWith(
          status: MessageStatus.delivered,
        );
        notifyListeners();
        await _saveMessages();
      }

      // Call API
      final response = await ChatService.sendMessage(text.trim());
      
      // Clear typing indicator
      _hideTypingIndicator();

      if (response != null) {
        // Create AI response message
        final aiMessage = ChatMessage(
          id: _generateMessageId(),
          text: response,
          senderType: SenderType.ai,
          timestamp: DateTime.now(),
          parsedParts: MessageParserService.parseMessage(response),
        );

        // Add AI message to list
        _messages.add(aiMessage);
        // Keep only the last 100 messages
        if (_messages.length > 100) {
          _messages = _messages.sublist(_messages.length - 100);
        }
        notifyListeners();
        await _saveMessages();

        // Remove delayed _updateMessageStatus (no longer needed)
        // await _updateMessageStatus(userMessage.id);
      } else {
        // Handle API error
        final errorMessage = ChatMessage(
          id: _generateMessageId(),
          text: 'عذراً، حدث خطأ في إرسال الرسالة. يرجى المحاولة مرة أخرى.',
          senderType: SenderType.ai,
          timestamp: DateTime.now(),
          parsedParts: MessageParserService.parseMessage('عذراً، حدث خطأ في إرسال الرسالة. يرجى المحاولة مرة أخرى.'),
        );

        _messages.add(errorMessage);
        // Keep only the last 100 messages
        if (_messages.length > 100) {
          _messages = _messages.sublist(_messages.length - 100);
        }
        notifyListeners();
        await _saveMessages();
      }

    } catch (e) {
      Logger.log('ChatProvider: Error sending message - $e');
      _hideTypingIndicator();
      
      // Add error message
      final errorMessage = ChatMessage(
        id: _generateMessageId(),
        text: 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.',
        senderType: SenderType.ai,
        timestamp: DateTime.now(),
        parsedParts: MessageParserService.parseMessage('حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.'),
      );

      _messages.add(errorMessage);
      // Keep only the last 100 messages
      if (_messages.length > 100) {
        _messages = _messages.sublist(_messages.length - 100);
      }
      notifyListeners();
      await _saveMessages();
    } finally {
      // Clean up
      _activeApiCalls.remove(messageId);
      _pendingApiCallId = null;
      await LocalStorageService.clearPendingApiCall();
    }
  }

  // Update message status with realistic timing

  // Show typing indicator
  void _showTypingIndicator() {
    _isTyping = true;
    notifyListeners();

    // Safety timeout to prevent stuck typing indicator
    _safetyTimeout?.cancel();
    _safetyTimeout = Timer(const Duration(seconds: 30), () {
      if (_isTyping) {
        Logger.log('ChatProvider: Safety timeout triggered for typing indicator');
        _hideTypingIndicator();
      }
    });
  }

  // Hide typing indicator
  void _hideTypingIndicator() {
    _isTyping = false;
    _safetyTimeout?.cancel();
    notifyListeners();
  }

  // Delete all messages
  Future<void> deleteThread() async {
    if (_deleteThreadsLoading) return;

    try {
      _deleteThreadsLoading = true;
      notifyListeners();

      // Call API to delete threads
      final success = await ChatService.deleteThreads();

      if (success) {
        // Clear local messages
        _messages.clear();
        await LocalStorageService.clearMessages();
        await LocalStorageService.clearPendingApiCall();
        
        // Clear active API calls
        _activeApiCalls.clear();
        _pendingApiCallId = null;
        
        Logger.log('ChatProvider: Thread deleted successfully');
      } else {
        Logger.log('ChatProvider: Failed to delete thread from server');
      }

    } catch (e) {
      Logger.log('ChatProvider: Error deleting thread - $e');
    } finally {
      _deleteThreadsLoading = false;
      notifyListeners();
    }
  }

  // Recover pending API calls after app restart
  Future<void> _recoverPendingApiCall() async {
    try {
      final pendingCallId = await LocalStorageService.loadPendingApiCall();
      if (pendingCallId != null) {
        _pendingApiCallId = pendingCallId;
        _activeApiCalls.add(pendingCallId);
        Logger.log('ChatProvider: Recovered pending API call - $pendingCallId');
      }
    } catch (e) {
      Logger.log('ChatProvider: Error recovering pending API call - $e');
    }
  }

  // Generate unique message ID
  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  // Handle navigation to apartment/share details
  void handleLinkTap(String linkType, String referenceId, BuildContext context) {
    try {
      Logger.log('ChatProvider: Handling link tap - $linkType:$referenceId');
      
      if (linkType == 'apartment') {
        // Navigate to apartment details
        Navigator.pushNamed(context, '/property_details', arguments: referenceId);
      } else if (linkType == 'share') {
        // Navigate to share details
        Navigator.pushNamed(context, '/share_details', arguments: referenceId);
      }
    } catch (e) {
      Logger.log('ChatProvider: Error handling link tap - $e');
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _safetyTimeout?.cancel();
    super.dispose();
  }

  // Static method to get provider instance
  static ChatProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<ChatProvider>(context, listen: listen);
  }
} 