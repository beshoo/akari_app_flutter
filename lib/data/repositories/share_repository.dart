import 'package:akari_app/data/models/share_model.dart';
import 'package:akari_app/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// Response model for sectors grouped by region
class SectorResponse {
  final Map<String, dynamic> data;

  SectorResponse({required this.data});

  factory SectorResponse.fromJson(Map<String, dynamic> json) {
    return SectorResponse(data: json);
  }
}

// Model for individual sector in dropdown
class SectorOption {
  final int id;
  final String name;
  final String code;

  SectorOption({
    required this.id,
    required this.name,
    required this.code,
  });

  factory SectorOption.fromJson(Map<String, dynamic> json) {
    return SectorOption(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }
}

// Model for sector type in dropdown
class SectorTypeOption {
  final String id;
  final String name;

  SectorTypeOption({
    required this.id,
    required this.name,
  });

  factory SectorTypeOption.fromJson(Map<String, dynamic> json) {
    return SectorTypeOption(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

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
  }

  Future<SharePaginatedResponse> refreshShares({
    required int regionId,
  }) async {
    // Force refresh by always starting from page 1
    return fetchShares(regionId: regionId, page: 1);
  }

  /// Create a new buy share request
  Future<Map<String, dynamic>> createBuyShare({
    required int regionId,
    required int sectorId,
    required int quantity,
    required String ownerName,
    required double price,
  }) async {
    final response = await _dio.post('/share/buy', data: {
      'region_id': regionId,
      'sector_id': sectorId,
      'quantity': quantity,
      'owner_name': ownerName,
      'price': price,
    });

    if (kDebugMode) {
      print("------- Create Buy Share Response -------");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.data}");
      print("-----------------------------------------");
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data ?? {};
    } else {
      throw Exception('API returned status code ${response.statusCode}');
    }
  }

  /// Create a new sell share request
  Future<Map<String, dynamic>> createSellShare({
    required int regionId,
    required int sectorId,
    required int quantity,
    required String ownerName,
    required double price,
  }) async {
    final formData = FormData.fromMap({
      'region_id': regionId,
      'sector_id': sectorId,
      'quantity': quantity,
      'owner_name': ownerName,
      'price': price,
    });

    final response = await _dio.post('/share/sell', data: formData);

    if (kDebugMode) {
      print("------- Create Sell Share Response -------");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.data}");
      print("------------------------------------------");
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data ?? {};
    } else {
      throw Exception('API returned status code ${response.statusCode}');
    }
  }

  /// Update an existing share
  Future<Map<String, dynamic>> updateShare({
    required int shareId,
    required int regionId,
    required int sectorId,
    required int quantity,
    required String ownerName,
    required double price,
  }) async {
    final response = await _dio.post('/share/update/$shareId', data: {
      'region_id': regionId,
      'sector_id': sectorId,
      'quantity': quantity,
      'owner_name': ownerName,
      'price': price,
    });

    if (kDebugMode) {
      print("------- Update Share Response -------");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.data}");
      print("-------------------------------------");
    }

    if (response.statusCode == 200) {
      return response.data ?? {};
    } else {
      throw Exception('API returned status code ${response.statusCode}');
    }
  }

  /// Search for shares with filters
  Future<SharePaginatedResponse> searchShares({
    int? regionId,
    int? sectorId,
    String? transactionType,
    double? minPrice,
    double? maxPrice,
    int? minQuantity,
    int? maxQuantity,
    int page = 1,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
    };

    if (regionId != null) queryParameters['region_id'] = regionId;
    if (sectorId != null) queryParameters['sector_id'] = sectorId;
    if (transactionType != null) queryParameters['transaction_type'] = transactionType;
    if (minPrice != null) queryParameters['min_price'] = minPrice;
    if (maxPrice != null) queryParameters['max_price'] = maxPrice;
    if (minQuantity != null) queryParameters['min_quantity'] = minQuantity;
    if (maxQuantity != null) queryParameters['max_quantity'] = maxQuantity;

    final response = await _dio.get('/share/search', queryParameters: queryParameters);

    if (kDebugMode) {
      print("------- Search Shares Response -------");
      print("Status Code: ${response.statusCode}");
      print("URL: ${response.requestOptions.uri}");
      print("Data Count: ${response.data?['data']?.length ?? 0}");
      print("--------------------------------------");
    }

    if (response.statusCode == 200 && response.data != null) {
      return SharePaginatedResponse.fromJson(response.data);
    } else {
      throw Exception('API returned status code ${response.statusCode}');
    }
  }

  /// Fetch sectors grouped by region
  Future<SectorResponse> fetchSectorsByRegion(int regionId) async {
    final response = await _dio.get('/sector/list/$regionId');

    if (kDebugMode) {
      print("------- Fetch Sectors Response -------");
      print("Status Code: ${response.statusCode}");
      print("URL: ${response.requestOptions.uri}");
      print("Response: ${response.data}");
      print("--------------------------------------");
    }

    if (response.statusCode == 200 && response.data != null) {
      return SectorResponse.fromJson(response.data);
    } else {
      throw Exception('API returned status code ${response.statusCode}');
    }
  }

  /// Get a specific share by ID (for editing)
  Future<Share?> getShareById(int shareId) async {
    final response = await _dio.get('/share/$shareId');

    if (kDebugMode) {
      print("------- Get Share By ID Response -------");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.data}");
      print("----------------------------------------");
    }

    if (response.statusCode == 200 && response.data != null) {
      return Share.fromJson(response.data);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('API returned status code ${response.statusCode}');
    }
  }
} 