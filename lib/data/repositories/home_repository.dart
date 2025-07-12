import 'package:akari_app/data/models/region_model.dart';
import 'package:akari_app/data/models/statistics_model.dart';
import 'package:akari_app/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class HomeRepository {
  final Dio _dio = ApiService.instance;

  Future<List<Region>> fetchRegions() async {
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
  }

  Future<StatisticsResponse> fetchStatistics() async {
    final response = await _dio.get('/statistics');
    if (response.statusCode == 200 && response.data != null) {
      return StatisticsResponse.fromJson(response.data);
    } else {
      throw Exception(
          'API returned status code ${response.statusCode} or null data');
    }
  }
} 