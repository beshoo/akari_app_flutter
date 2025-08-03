import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/chat_message_model.dart';
import '../services/chat_service.dart';
import '../services/local_storage_service.dart';
import '../services/local_notification_service.dart';
import '../services/message_parser_service.dart';
import '../utils/logger.dart';

class ChatStore extends ChangeNotifier {
  // Timeout constants
  static const int _apiTimeoutSeconds = 130; // 120 seconds HTTP + 10 seconds buffer
  static const int _typingTimeoutSeconds = 140; // Slightly longer than API timeout
  
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
  
  // Notification tracking
  bool _shouldShowNotification = false;
  
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
      
      // Save typing state separately for quick access
      await prefs.setBool(_typingStateKey, _isTyping);
      
      // Save pending call state
      if (_pendingApiCallId != null) {
        await prefs.setString(_pendingCallStateKey, _pendingApiCallId!);
      } else {
        await prefs.remove(_pendingCallStateKey);
      }
      
      // Save basic state information as individual preferences instead of complex map
      await prefs.setInt('messages_count', _messages.length);
      await prefs.setStringList('active_api_calls', _activeApiCalls.toList());
      await prefs.setInt('last_updated', DateTime.now().millisecondsSinceEpoch);
      
      Logger.log('ChatStore: State persisted successfully');
    } catch (e) {
      Logger.log('ChatStore: Error saving state - $e');
      // Don't rethrow - state saving failure shouldn't break the chat
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
      
      // Load active API calls
      final activeCallsList = prefs.getStringList('active_api_calls') ?? [];
      _activeApiCalls.clear();
      _activeApiCalls.addAll(activeCallsList);
      
      if (_pendingApiCallId != null && !_activeApiCalls.contains(_pendingApiCallId!)) {
        _activeApiCalls.add(_pendingApiCallId!);
        Logger.log('ChatStore: Recovered pending API call - $_pendingApiCallId');
      }
      
      Logger.log('ChatStore: Loaded persisted state - typing: $_isTyping, pending: $_pendingApiCallId, active calls: ${_activeApiCalls.length}');
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
    final startTime = DateTime.now();
    try {
      Logger.log('ChatStore: Executing API call for message: $messageId');
      Logger.log('ChatStore: Message content: $message');
      Logger.log('ChatStore: API call started at: $startTime');
      
      // Call API - this should continue even if user leaves the page
      Logger.log('ChatStore: About to call ChatService.sendMessage');
      final response = await ChatService.sendMessage(message);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      Logger.log('ChatStore: ChatService.sendMessage returned after ${duration.inSeconds} seconds');
      
      // Cancel the safety timeout since API call completed successfully
      _safetyTimeout?.cancel();
      Logger.log('ChatStore: Safety timeout cancelled for message: $messageId');
      
      Logger.log('ChatStore: API call completed for message: $messageId');
      Logger.log('ChatStore: Response is null: ${response == null}');
      if (response != null) {
        Logger.log('ChatStore: Response length: ${response.length}');
        Logger.log('ChatStore: Response content: ${response.length > 100 ? response.substring(0, 100) : response}...');
      }
      
      if (response != null) {
        try {
          Logger.log('ChatStore: Starting to create AI response message');
          
          // Create AI response message
          List<MessagePart> parsedParts;
          try {
            Logger.log('ChatStore: Parsing message with MessageParserService');
            parsedParts = MessageParserService.parseMessage(response);
            Logger.log('ChatStore: Message parsed successfully, parts count: ${parsedParts.length}');
          } catch (parseError) {
            Logger.log('ChatStore: Error parsing message - $parseError');
            // Fallback to simple text part
            parsedParts = [MessagePart(text: response)];
            Logger.log('ChatStore: Using fallback parsing');
          }
          
          final aiMessage = ChatMessage(
            id: _generateMessageId(),
            text: response,
            senderType: SenderType.ai,
            timestamp: DateTime.now(),
            parsedParts: parsedParts,
          );
          
          Logger.log('ChatStore: AI message created successfully');

          // Add AI message to list
          _messages.add(aiMessage);
          if (_messages.length > 100) {
            _messages = _messages.sublist(_messages.length - 100);
          }
          
          Logger.log('ChatStore: AI response created and added to messages');
          
          // Save messages with error handling
          try {
            await _saveMessages();
            Logger.log('ChatStore: Messages saved successfully');
          } catch (saveError) {
            Logger.log('ChatStore: Error saving messages - $saveError');
            // Continue anyway - don't let save errors break the response display
          }
          
          // Hide typing indicator with error handling
          try {
            await _hideTypingIndicator();
            Logger.log('ChatStore: Typing indicator hidden');
          } catch (typingError) {
            Logger.log('ChatStore: Error hiding typing indicator - $typingError');
            // Continue anyway
          }
          
                    // Notify listeners with error handling
          try {
            notifyListeners();
            Logger.log('ChatStore: UI updated successfully');
          } catch (notifyError) {
            Logger.log('ChatStore: Error notifying listeners - $notifyError');
          }
          
          // Show notification if user is not on chat page
          await _showNotificationIfNeeded(response);
          
          Logger.log('ChatStore: AI response processing completed successfully');
      } catch (processingError) {
        Logger.log('ChatStore: Error processing AI response - $processingError');
        // Cancel the safety timeout since we're handling the processing error
        _safetyTimeout?.cancel();
        // If we fail to process the response, show the raw response as text
        try {
          final fallbackMessage = ChatMessage(
            id: _generateMessageId(),
            text: response,
            senderType: SenderType.ai,
            timestamp: DateTime.now(),
            parsedParts: [MessagePart(text: response)],
          );
          _messages.add(fallbackMessage);
          notifyListeners();
          await _hideTypingIndicator();
          Logger.log('ChatStore: Fallback message created');
        } catch (fallbackError) {
          Logger.log('ChatStore: Fallback processing also failed - $fallbackError');
          await _addErrorMessage('تم استلام الرد لكن حدث خطأ في عرضه. الرد: $response');
          await _hideTypingIndicator();
        }
      }
      } else {
        Logger.log('ChatStore: API returned null response');
        // Cancel the safety timeout since we're handling the null response
        _safetyTimeout?.cancel();
        await _addErrorMessage('عذراً، حدث خطأ في إرسال الرسالة. يرجى المحاولة مرة أخرى.');
        await _hideTypingIndicator();
      }

    } catch (e) {
      Logger.log('ChatStore: API call error - $e');
      // Cancel the safety timeout since we're handling the error
      _safetyTimeout?.cancel();
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
    
    // Set up timeout that matches the HTTP timeout
    _safetyTimeout = Timer(const Duration(seconds: _apiTimeoutSeconds), () async {
      Logger.log('ChatStore: API call timeout reached for: $messageId after $_apiTimeoutSeconds seconds');
      await _hideTypingIndicator();
      await _addErrorMessage('انتهت مهلة الاستعلام ($_apiTimeoutSeconds ثانية). يرجى المحاولة مرة أخرى.');
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
    try {
      final errorMessage = ChatMessage(
        id: _generateMessageId(),
        text: errorText,
        senderType: SenderType.ai,
        timestamp: DateTime.now(),
        parsedParts: [MessagePart(text: errorText)], // Use simple parsing for error messages
      );

      _messages.add(errorMessage);
      if (_messages.length > 100) {
        _messages = _messages.sublist(_messages.length - 100);
      }
      
      // Try to save but don't let save failures prevent error message display
      try {
        await _saveMessages();
      } catch (saveError) {
        Logger.log('ChatStore: Error saving error message - $saveError');
      }
      
      // Try to notify listeners but don't let this fail
      try {
        notifyListeners();
      } catch (notifyError) {
        Logger.log('ChatStore: Error notifying listeners for error message - $notifyError');
      }
      
      Logger.log('ChatStore: Error message added successfully');
    } catch (e) {
      Logger.log('ChatStore: Failed to add error message - $e');
      // Last resort - just try to notify with whatever state we have
      try {
        notifyListeners();
      } catch (finalError) {
        Logger.log('ChatStore: Final error notification failed - $finalError');
      }
    }
  }

  // Show typing indicator
  Future<void> _showTypingIndicator() async {
    _isTyping = true;
    await _saveState();
    notifyListeners();

    // Safety timeout to prevent stuck typing indicator
    _safetyTimeout?.cancel();
    _safetyTimeout = Timer(const Duration(seconds: _typingTimeoutSeconds), () async {
      if (_isTyping) {
        Logger.log('ChatStore: Safety timeout triggered for typing indicator after $_typingTimeoutSeconds seconds');
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

  // Set notification flag when user leaves chat page
  void setNotificationFlag(bool shouldShow) {
    _shouldShowNotification = shouldShow;
    Logger.log('ChatStore: Notification flag set to $_shouldShowNotification');
  }

  // Show notification if user is not on chat page
  Future<void> _showNotificationIfNeeded(String response) async {
    if (_shouldShowNotification) {
      try {
        // Truncate response for notification
        final notificationBody = response.length > 100 
            ? '${response.substring(0, 100)}...' 
            : response;
        
        await LocalNotificationService.showChatResponseNotification(
          title: 'رد جديد من الذكاء الاصطناعي',
          body: notificationBody,
          payload: 'chat',
        );
        
        Logger.log('ChatStore: Notification shown for chat response');
      } catch (e) {
        Logger.log('ChatStore: Error showing notification - $e');
      }
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