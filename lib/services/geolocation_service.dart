import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:phone_form_field/phone_form_field.dart';
import '../utils/logger.dart';

class GeolocationService {
  static const String _apiUrl = 'https://geo.brdtest.com/mygeo.json';

  /// Fetches the user's country code from IP geolocation
  static Future<String?> getUserCountryCode() async {
    try {
      final dio = Dio();
      final response = await dio.get(_apiUrl);
      
      if (response.statusCode == 200) {
        final data = response.data;
        final countryCode = data['country'] as String?;
        
        Logger.log('Geolocation API response: $data');
        Logger.log('Detected country code: $countryCode');
        
        return countryCode;
      } else {
        Logger.log('Geolocation API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      Logger.log('Geolocation service error: $e');
      return null;
    }
  }

  /// Converts country code to IsoCode
  static IsoCode? getIsoCodeFromCountryCode(String countryCode) {
    try {
      return IsoCode.values.firstWhere(
        (iso) => iso.name == countryCode,
        orElse: () => IsoCode.SY, // Default to Syria if not found
      );
    } catch (e) {
      Logger.log('Error converting country code to IsoCode: $e');
      return IsoCode.SY; // Default to Syria
    }
  }

  /// Gets the user's country IsoCode automatically
  static Future<IsoCode> getAutoDetectedCountry() async {
    final countryCode = await getUserCountryCode();
    
    if (countryCode != null) {
      final isoCode = getIsoCodeFromCountryCode(countryCode);
      Logger.log('Auto-detected country: $countryCode -> $isoCode');
      return isoCode ?? IsoCode.SY;
    }
    
    Logger.log('Failed to detect country, using default: SY');
    return IsoCode.SY; // Default to Syria
  }
} 