import 'package:akari_app/data/models/region_model.dart';
import 'package:akari_app/data/models/statistics_model.dart';
import 'package:akari_app/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class HomeRepository {
  final Dio _dio = ApiService.instance;

  Future<List<Region>> fetchRegions() async {
    try {
      final response = await _dio.get('/region/list');

      if (kDebugMode) {
        print("------- Region API Response -------");
        print("Status Code: ${response.statusCode}");
        print("Headers: ${response.headers}");
        print("Data: ${response.data}");
        if (response.data != null) {
          print("Data runtimeType: ${response.data.runtimeType}");
        }
        print("---------------------------------");
      }

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          final List<dynamic> regionList = response.data;
          return regionList.map((json) => Region.fromJson(json)).toList();
        } else {
          throw Exception(
              'API response data is not a List, but ${response.data.runtimeType}');
        }
      } else if (response.statusCode != 200) {
        throw Exception('API returned status code ${response.statusCode}');
      } else {
        throw Exception('API returned null data');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print("DioException in fetchRegions: ${e.message}");
        print("DioException response: ${e.response}");
      }
      throw Exception('Failed to load regions due to a network error: $e');
    } catch (e, stacktrace) {
      if (kDebugMode) {
        print("Unexpected error in fetchRegions: $e");
        print(stacktrace);
      }
      throw Exception('Failed to load regions due to an unexpected error: $e');
    }
  }

  Future<StatisticsResponse> fetchStatistics() async {
    try {
      final response = await _dio.get('/statistics');
      if (response.statusCode == 200 && response.data != null) {
        return StatisticsResponse.fromJson(response.data);
      } else {
        throw Exception(
            'API returned status code ${response.statusCode} or null data');
      }
    } catch (e) {
      throw Exception('Failed to load statistics: $e');
    }
  }
} 