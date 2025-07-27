import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/models/chat_message_model.dart';
import '../utils/logger.dart';

class LocalStorageService {
  static const String _messagesKey = 'chat_messages';
  static const String _pendingApiCallKey = 'pending_api_call';
  static const String _lastMessageIdKey = 'last_message_id';
  
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Message Persistence
  static Future<void> saveMessages(List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Only keep the last 100 messages
      final trimmedMessages = messages.length > 100
          ? messages.sublist(messages.length - 100)
          : messages;
      final messagesJson = trimmedMessages.map((message) => message.toJson()).toList();
      await prefs.setString(_messagesKey, jsonEncode(messagesJson));
      Logger.log('LocalStorageService: Saved  [1m${trimmedMessages.length} [0m messages');
    } catch (e) {
      Logger.log('LocalStorageService: Error saving messages - $e');
    }
  }

  static Future<List<ChatMessage>> loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesString = prefs.getString(_messagesKey);
      
      if (messagesString != null) {
        final messagesJson = jsonDecode(messagesString) as List;
        final messages = messagesJson
            .map((json) => ChatMessage.fromJson(json))
            .toList();
        Logger.log('LocalStorageService: Loaded ${messages.length} messages');
        return messages;
      }
    } catch (e) {
      Logger.log('LocalStorageService: Error loading messages - $e');
    }
    
    return [];
  }

  static Future<void> clearMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_messagesKey);
      Logger.log('LocalStorageService: Cleared all messages');
    } catch (e) {
      Logger.log('LocalStorageService: Error clearing messages - $e');
    }
  }

  // Pending API Call Recovery
  static Future<void> savePendingApiCall(String messageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingApiCallKey, messageId);
      Logger.log('LocalStorageService: Saved pending API call - $messageId');
    } catch (e) {
      Logger.log('LocalStorageService: Error saving pending API call - $e');
    }
  }

  static Future<String?> loadPendingApiCall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingCall = prefs.getString(_pendingApiCallKey);
      Logger.log('LocalStorageService: Loaded pending API call - $pendingCall');
      return pendingCall;
    } catch (e) {
      Logger.log('LocalStorageService: Error loading pending API call - $e');
      return null;
    }
  }

  static Future<void> clearPendingApiCall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingApiCallKey);
      Logger.log('LocalStorageService: Cleared pending API call');
    } catch (e) {
      Logger.log('LocalStorageService: Error clearing pending API call - $e');
    }
  }

  // Message ID Management
  static Future<void> saveLastMessageId(String messageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastMessageIdKey, messageId);
    } catch (e) {
      Logger.log('LocalStorageService: Error saving last message ID - $e');
    }
  }

  static Future<String?> loadLastMessageId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastMessageIdKey);
    } catch (e) {
      Logger.log('LocalStorageService: Error loading last message ID - $e');
      return null;
    }
  }

  // Secure Storage for User Data
  static Future<void> saveSecureData(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      Logger.log('LocalStorageService: Saved secure data for key - $key');
    } catch (e) {
      Logger.log('LocalStorageService: Error saving secure data - $e');
    }
  }

  static Future<String?> loadSecureData(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      Logger.log('LocalStorageService: Loaded secure data for key - $key');
      return value;
    } catch (e) {
      Logger.log('LocalStorageService: Error loading secure data - $e');
      return null;
    }
  }

  static Future<void> clearSecureData(String key) async {
    try {
      await _secureStorage.delete(key: key);
      Logger.log('LocalStorageService: Cleared secure data for key - $key');
    } catch (e) {
      Logger.log('LocalStorageService: Error clearing secure data - $e');
    }
  }

  static Future<void> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
      Logger.log('LocalStorageService: Cleared all secure data');
    } catch (e) {
      Logger.log('LocalStorageService: Error clearing all secure data - $e');
    }
  }

  // Complete Data Migration and Cleanup
  static Future<void> clearAllData() async {
    try {
      // Clear regular storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Clear secure storage
      await _secureStorage.deleteAll();
      
      Logger.log('LocalStorageService: Cleared all data');
    } catch (e) {
      Logger.log('LocalStorageService: Error clearing all data - $e');
    }
  }

  // Data Migration Helper
  static Future<void> migrateData() async {
    try {
      // Check for old data formats and migrate if necessary
      final prefs = await SharedPreferences.getInstance();
      final version = prefs.getInt('data_version') ?? 0;
      
      if (version < 1) {
        // Perform migration for version 1
        // Add any migration logic here
        await prefs.setInt('data_version', 1);
        Logger.log('LocalStorageService: Migrated data to version 1');
      }
    } catch (e) {
      Logger.log('LocalStorageService: Error during data migration - $e');
    }
  }
} 