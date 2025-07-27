import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/chat_message_model.dart';
import '../services/chat_service.dart';
import '../services/local_storage_service.dart';
import '../services/message_parser_service.dart';
import '../utils/logger.dart';

class ChatStore extends ChangeNotifier {
  // Chat state
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _deleteThreadsLoading = false;
  bool _isInitialized = false;
  
  // API call tracking
  final Set<String> _activeApiCalls = {};
  String? _pendingApiCallId;
  Timer? _typingTimer;
  Timer? _safetyTimeout;
  Timer? _backgroundApiTimer;
  
  // Persistence keys
  static const String _chatStateKey = 'chat_store_state';
  static const String _typingStateKey = 'chat_typing_state';
  static const String _pendingCallStateKey = 'chat_pending_call_state';
  static const String _pendingMessagePrefix = 'chat_pending_message_';

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
  bool get isInitialized => _isInitialized;
  Set<String> get activeApiCalls => _activeApiCalls;
  String? get pendingApiCallId => _pendingApiCallId;

  ChatStore() {
    _initializeStore();
  }

  Future<void> _initializeStore() async {
    try {
      Logger.log('ChatStore: Initializing store...');
      
      // Load persisted chat state
      await _loadPersistedState();
      
      // Load messages from storage
      await loadMessages();
      
      // Check for and recover any pending API calls
      await _recoverPendingApiCalls();
      
      // Perform data migration if needed
      await LocalStorageService.migrateData();
      
      _isInitialized = true;
      notifyListeners();
      
      Logger.log('ChatStore: Store initialized successfully');
    } catch (e) {
      Logger.log('ChatStore: Error during initialization - $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Load messages from local storage
  Future<void> loadMessages() async {
    try {
      _messages = await LocalStorageService.loadMessages();
      await _saveState();
      notifyListeners();
      Logger.log('ChatStore: Loaded ${_messages.length} messages');
    } catch (e) {
      Logger.log('ChatStore: Error loading messages - $e');
    }
  }

  // Save messages to local storage
  Future<void> _saveMessages() async {
    try {
      await LocalStorageService.saveMessages(_messages);
      await _saveState();
    } catch (e) {
      Logger.log('ChatStore: Error saving messages - $e');
    }
  }

  // Persist complete store state
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save main state
      final stateMap = {
        'messages_count': _messages.length,
        'is_typing': _isTyping,
        'active_api_calls': _activeApiCalls.toList(),
        'pending_api_call_id': _pendingApiCallId,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      };
      
      await prefs.setString(_chatStateKey, 
        Map<String, dynamic>.from(stateMap).toString());
      
      // Save typing state separately for quick access
      await prefs.setBool(_typingStateKey, _isTyping);
      
      // Save pending call state
      if (_pendingApiCallId != null) {
        await prefs.setString(_pendingCallStateKey, _pendingApiCallId!);
      } else {
        await prefs.remove(_pendingCallStateKey);
      }
      
      Logger.log('ChatStore: State persisted successfully');
    } catch (e) {
      Logger.log('ChatStore: Error saving state - $e');
    }
  }

  // Load persisted state
  Future<void> _loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load typing state
      _isTyping = prefs.getBool(_typingStateKey) ?? false;
      
      // Load pending API call
      _pendingApiCallId = prefs.getString(_pendingCallStateKey);
      
      if (_pendingApiCallId != null) {
        _activeApiCalls.add(_pendingApiCallId!);
        Logger.log('ChatStore: Recovered pending API call - $_pendingApiCallId');
      }
      
      Logger.log('ChatStore: Loaded persisted state - typing: $_isTyping, pending: $_pendingApiCallId');
    } catch (e) {
      Logger.log('ChatStore: Error loading persisted state - $e');
    }
  }

  // Send a message
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final messageId = _generateMessageId();
    
    // Check for duplicate API calls
    if (_activeApiCalls.contains(messageId)) {
      Logger.log('ChatStore: Duplicate API call prevented for $messageId');
      return;
    }

    // Prevent duplicate messages
    final trimmedText = text.trim();
    final lastMessage = _messages.isNotEmpty ? _messages.last : null;
    if (lastMessage != null && 
        lastMessage.text == trimmedText && 
        lastMessage.senderType == SenderType.user &&
        DateTime.now().difference(lastMessage.timestamp).inSeconds < 2) {
      Logger.log('ChatStore: Duplicate message prevented');
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
      if (_messages.length > 100) {
        _messages = _messages.sublist(_messages.length - 100);
      }
      
      // Save state immediately
      await _saveMessages();
      notifyListeners();

      // Track pending API call
      _pendingApiCallId = messageId;
      _activeApiCalls.add(messageId);
      await _saveState();

      // Show typing indicator with delay
      await Future.delayed(const Duration(milliseconds: 1500));
      await _showTypingIndicator();

      // Mark user message as delivered
      final lastUserMsgIndex = _messages.lastIndexWhere((msg) => msg.senderType == SenderType.user);
      if (lastUserMsgIndex != -1) {
        _messages[lastUserMsgIndex] = _messages[lastUserMsgIndex].copyWith(
          status: MessageStatus.delivered,
        );
        await _saveMessages();
        notifyListeners();
      }

      // Start background API call - this will continue even if user leaves the page
      _performBackgroundApiCall(text.trim(), messageId);

    } catch (e) {
      Logger.log('ChatStore: Error sending message - $e');
      await _hideTypingIndicator();
      await _addErrorMessage('حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.');
      _cleanupApiCall(messageId);
    }
  }

  // Perform API call that survives page navigation
  Future<void> _performBackgroundApiCall(String message, String messageId) async {
    Logger.log('ChatStore: Starting background API call for message: $messageId');
    
    // Save the message text for potential retry
    await _savePendingApiCallMessage(messageId, message);
    
    // Run API call with timeout handling
    _executeApiCallWithTimeout(message, messageId);
  }
  
  // Execute the actual API call independently
  Future<void> _executeApiCall(String message, String messageId) async {
    try {
      Logger.log('ChatStore: Executing API call for message: $messageId');
      
      // Call API - this should continue even if user leaves the page
      final response = await ChatService.sendMessage(message);
      
      Logger.log('ChatStore: API call completed for message: $messageId, response: ${response?.substring(0, 50)}...');
      
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
        if (_messages.length > 100) {
          _messages = _messages.sublist(_messages.length - 100);
        }
        
        await _saveMessages();
        await _hideTypingIndicator();
        notifyListeners();
        
        Logger.log('ChatStore: AI response saved and UI updated');
      } else {
        Logger.log('ChatStore: API returned null response');
        await _addErrorMessage('عذراً، حدث خطأ في إرسال الرسالة. يرجى المحاولة مرة أخرى.');
        await _hideTypingIndicator();
      }

    } catch (e) {
      Logger.log('ChatStore: API call error - $e');
      await _addErrorMessage('حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.');
      await _hideTypingIndicator();
    } finally {
      // Clean up
      await _cleanupApiCall(messageId);
      await _clearPendingApiCallMessage(messageId);
    }
  }

  // Execute API call with better timeout handling
  void _executeApiCallWithTimeout(String message, String messageId) {
    Logger.log('ChatStore: Starting API call with timeout for: $messageId');
    Logger.log('ChatStore: Message content: ${message.substring(0, message.length > 50 ? 50 : message.length)}...');
    
    // Cancel any existing safety timeout
    _safetyTimeout?.cancel();
    
    // Set up a more aggressive timeout for recovery calls
    _safetyTimeout = Timer(const Duration(seconds: 45), () async {
      Logger.log('ChatStore: API call timeout reached for: $messageId');
      await _hideTypingIndicator();
      await _addErrorMessage('انتهت مهلة الاستعلام. يرجى المحاولة مرة أخرى.');
      await _cleanupApiCall(messageId);
      await _clearPendingApiCallMessage(messageId);
    });
    
    // First test connectivity
    ChatService.testConnection().then((isConnected) {
      Logger.log('ChatStore: API connectivity test result: $isConnected');
      if (isConnected) {
        // Execute the API call
        _executeApiCall(message, messageId).catchError((error) {
          Logger.log('ChatStore: API call with timeout failed - $error');
        });
      } else {
        Logger.log('ChatStore: API not accessible, will retry later');
        // Will be retried when user returns to chat page
      }
    }).catchError((error) {
      Logger.log('ChatStore: Connectivity test failed - $error');
      // Proceed with API call anyway
      _executeApiCall(message, messageId).catchError((error) {
        Logger.log('ChatStore: API call with timeout failed - $error');
      });
    });
  }

  // Add error message
  Future<void> _addErrorMessage(String errorText) async {
    final errorMessage = ChatMessage(
      id: _generateMessageId(),
      text: errorText,
      senderType: SenderType.ai,
      timestamp: DateTime.now(),
      parsedParts: MessageParserService.parseMessage(errorText),
    );

    _messages.add(errorMessage);
    if (_messages.length > 100) {
      _messages = _messages.sublist(_messages.length - 100);
    }
    
    await _saveMessages();
    notifyListeners();
  }

  // Show typing indicator
  Future<void> _showTypingIndicator() async {
    _isTyping = true;
    await _saveState();
    notifyListeners();

    // Safety timeout to prevent stuck typing indicator
    _safetyTimeout?.cancel();
    _safetyTimeout = Timer(const Duration(seconds: 30), () async {
      if (_isTyping) {
        Logger.log('ChatStore: Safety timeout triggered for typing indicator');
        await _hideTypingIndicator();
      }
    });
  }

  // Hide typing indicator
  Future<void> _hideTypingIndicator() async {
    _isTyping = false;
    _safetyTimeout?.cancel();
    await _saveState();
    notifyListeners();
  }

  // Clean up API call tracking
  Future<void> _cleanupApiCall(String messageId) async {
    _activeApiCalls.remove(messageId);
    if (_pendingApiCallId == messageId) {
      _pendingApiCallId = null;
    }
    await _saveState();
  }

  // Recover any pending API calls after app restart or page return
  Future<void> _recoverPendingApiCalls() async {
    try {
      if (_pendingApiCallId != null && _activeApiCalls.contains(_pendingApiCallId!)) {
        Logger.log('ChatStore: Found pending API call during recovery: $_pendingApiCallId');
        
        // Check if the API call is still valid by checking the last user message
        if (_messages.isNotEmpty) {
          final lastMessage = _messages.last;
          if (lastMessage.senderType == SenderType.user) {
            Logger.log('ChatStore: Last message is from user, checking for pending API call');
            
            // Try to load the pending message
            final pendingMessage = await _loadPendingApiCallMessage(_pendingApiCallId!);
            if (pendingMessage != null) {
              Logger.log('ChatStore: Found pending message, restarting API call for: ${pendingMessage.substring(0, 30)}...');
              
              // Check if enough time has passed to avoid immediate restart loops
              final currentTime = DateTime.now().millisecondsSinceEpoch;
              final messageTime = int.tryParse(_pendingApiCallId!.split('_')[1]) ?? 0;
              final timeDiff = currentTime - messageTime;
              
              if (timeDiff < 300000) { // Less than 5 minutes old
                await _showTypingIndicator();
                
                // Add a small delay before restarting to avoid race conditions
                await Future.delayed(const Duration(milliseconds: 500));
                
                // Restart the API call with timeout handling
                Logger.log('ChatStore: Executing recovery API call');
                _executeApiCallWithTimeout(pendingMessage, _pendingApiCallId!);
              } else {
                Logger.log('ChatStore: Pending call too old, cleaning up');
                await _cleanupApiCall(_pendingApiCallId!);
                await _clearPendingApiCallMessage(_pendingApiCallId!);
              }
            } else {
              Logger.log('ChatStore: No pending message found, cleaning up stale state');
              await _cleanupApiCall(_pendingApiCallId!);
            }
          } else {
            // Last message is from AI, so the API call already completed
            Logger.log('ChatStore: Pending API call already completed, cleaning up');
            await _cleanupApiCall(_pendingApiCallId!);
          }
        }
      }
    } catch (e) {
      Logger.log('ChatStore: Error recovering pending API calls - $e');
    }
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
        // Clear local messages and state
        _messages.clear();
        await LocalStorageService.clearMessages();
        
        // Clear active API calls
        _activeApiCalls.clear();
        _pendingApiCallId = null;
        _isTyping = false;
        
        // Clear persisted state
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_chatStateKey);
        await prefs.remove(_typingStateKey);
        await prefs.remove(_pendingCallStateKey);
        
        Logger.log('ChatStore: Thread deleted successfully');
      } else {
        Logger.log('ChatStore: Failed to delete thread from server');
      }

    } catch (e) {
      Logger.log('ChatStore: Error deleting thread - $e');
    } finally {
      _deleteThreadsLoading = false;
      notifyListeners();
    }
  }

  // Generate unique message ID
  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  // Handle navigation to apartment/share details
  void handleLinkTap(String linkType, String referenceId, BuildContext context) {
    try {
      Logger.log('ChatStore: Handling link tap - $linkType:$referenceId');
      
      if (linkType == 'apartment') {
        Navigator.pushNamed(context, '/property_details', arguments: referenceId);
      } else if (linkType == 'share') {
        Navigator.pushNamed(context, '/share_details', arguments: referenceId);
      }
    } catch (e) {
      Logger.log('ChatStore: Error handling link tap - $e');
    }
  }

  // Public method to refresh state when user returns to chat page
  Future<void> refreshState() async {
    if (!_isInitialized) {
      await _initializeStore();
      return;
    }
    
    try {
      // Reload messages from storage in case they were updated by background operations
      await loadMessages();
      
      // Check for any completed API calls
      await _recoverPendingApiCalls();
      
      Logger.log('ChatStore: State refreshed successfully');
    } catch (e) {
      Logger.log('ChatStore: Error refreshing state - $e');
    }
  }

  // Save pending API call message for potential retry
  Future<void> _savePendingApiCallMessage(String messageId, String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_pendingMessagePrefix$messageId', message);
      Logger.log('ChatStore: Saved pending message for $messageId');
    } catch (e) {
      Logger.log('ChatStore: Error saving pending message - $e');
    }
  }

  // Clear pending API call message
  Future<void> _clearPendingApiCallMessage(String messageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_pendingMessagePrefix$messageId');
      Logger.log('ChatStore: Cleared pending message for $messageId');
    } catch (e) {
      Logger.log('ChatStore: Error clearing pending message - $e');
    }
  }

  // Load pending API call message
  Future<String?> _loadPendingApiCallMessage(String messageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_pendingMessagePrefix$messageId');
    } catch (e) {
      Logger.log('ChatStore: Error loading pending message - $e');
      return null;
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _safetyTimeout?.cancel();
    _backgroundApiTimer?.cancel();
    super.dispose();
  }
} 