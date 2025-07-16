import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'dart:convert';

class SecureStorage {
  static final _logger = Logger();
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  // Token management
  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: 'auth_token');
    } catch (e) {
      _logger.e('Error reading token', error: e);
      return null;
    }
  }
  
  static Future<void> setToken(String token) async {
    try {
      await _storage.write(key: 'auth_token', value: token);
    } catch (e) {
      _logger.e('Error saving token', error: e);
    }
  }
  
  static Future<void> deleteToken() async {
    try {
      await _storage.delete(key: 'auth_token');
    } catch (e) {
      _logger.e('Error deleting token', error: e);
    }
  }
  
  // User data management
  static Future<String?> getUserData(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      _logger.e('Error reading user data', error: e);
      return null;
    }
  }
  
  static Future<void> setUserData(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      _logger.e('Error saving user data', error: e);
    }
  }
  
  static Future<void> deleteUserData(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      _logger.e('Error deleting user data', error: e);
    }
  }
  
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      _logger.e('Error clearing storage', error: e);
    }
  }

  // Apartment dropdown data caching
  static Future<void> setApartmentDropdownData(String key, List<Map<String, dynamic>> data) async {
    try {
      final jsonString = jsonEncode(data);
      await _storage.write(key: 'apartment_$key', value: jsonString);
    } catch (e) {
      _logger.e('Error saving apartment dropdown data for $key', error: e);
    }
  }

  static Future<List<Map<String, dynamic>>?> getApartmentDropdownData(String key) async {
    try {
      final jsonString = await _storage.read(key: 'apartment_$key');
      if (jsonString != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(jsonString));
      }
      return null;
    } catch (e) {
      _logger.e('Error reading apartment dropdown data for $key', error: e);
      return null;
    }
  }

  static Future<void> deleteApartmentDropdownData(String key) async {
    try {
      await _storage.delete(key: 'apartment_$key');
    } catch (e) {
      _logger.e('Error deleting apartment dropdown data for $key', error: e);
    }
  }

  static Future<void> clearApartmentDropdownData() async {
    try {
      // Clear all apartment dropdown data
      await _storage.delete(key: 'apartment_directions');
      await _storage.delete(key: 'apartment_types');
      await _storage.delete(key: 'apartment_statuses');
      await _storage.delete(key: 'apartment_payment_methods');
    } catch (e) {
      _logger.e('Error clearing apartment dropdown data', error: e);
    }
  }
} 