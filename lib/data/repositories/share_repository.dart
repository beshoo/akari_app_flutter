import 'package:akari_app/data/models/share_model.dart';
import 'package:akari_app/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class SharePaginatedResponse {
  final List<Share> shares;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final String? nextPageUrl;
  final String? prevPageUrl;

  SharePaginatedResponse({
    required this.shares,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.nextPageUrl,
    this.prevPageUrl,
  });

  factory SharePaginatedResponse.fromJson(Map<String, dynamic> json) {
    return SharePaginatedResponse(
      shares: (json['data'] as List<dynamic>?)
          ?.map((item) => Share.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      total: json['total'] ?? 0,
      nextPageUrl: json['next_page_url'],
      prevPageUrl: json['prev_page_url'],
    );
  }

  bool get hasNextPage => nextPageUrl != null;
  bool get isLastPage => currentPage >= lastPage;
}

class ShareRepository {
  final Dio _dio = ApiService.instance;

  Future<SharePaginatedResponse> fetchShares({
    required int regionId,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get('/share/list/$regionId', queryParameters: {
        'page': page,
      });

      if (kDebugMode) {
        print("------- Share API Response -------");
        print("Status Code: ${response.statusCode}");
        print("URL: ${response.requestOptions.uri}");
        print("Current Page: ${response.data?['current_page']}");
        print("Total Items: ${response.data?['total']}");
        print("Data Count: ${response.data?['data']?.length ?? 0}");
        print("---------------------------------");
      }

      if (response.statusCode == 200 && response.data != null) {
        return SharePaginatedResponse.fromJson(response.data);
      } else {
        throw Exception('API returned status code ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print("DioException in fetchShares: ${e.message}");
        print("DioException response: ${e.response}");
      }
      
      if (e.response?.statusCode == 404) {
        throw Exception('لم يتم العثور على أسهم في هذه المنطقة');
      } else if (e.response?.statusCode == 401) {
        throw Exception('غير مصرح لك بالوصول إلى هذه البيانات');
      } else {
        throw Exception('فشل في تحميل الأسهم بسبب خطأ في الشبكة');
      }
    } catch (e, stacktrace) {
      if (kDebugMode) {
        print("Unexpected error in fetchShares: $e");
        print(stacktrace);
      }
      throw Exception('فشل في تحميل الأسهم بسبب خطأ غير متوقع: $e');
    }
  }

  Future<SharePaginatedResponse> refreshShares({
    required int regionId,
  }) async {
    // Force refresh by always starting from page 1
    return fetchShares(regionId: regionId, page: 1);
  }
} 