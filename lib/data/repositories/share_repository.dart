import 'package:akari_app/data/models/share_model.dart';
import 'package:akari_app/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:akari_app/utils/logger.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'data': shares.map((share) => share.toJson()).toList(),
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
      'next_page_url': nextPageUrl,
      'prev_page_url': prevPageUrl,
    };
  }
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

    Logger.log("------- Share API Response -------");
    Logger.log("Status Code: ${response.statusCode}");
    Logger.log("URL: ${response.requestOptions.uri}");
    Logger.log("Current Page: ${response.data?['current_page']}");
    Logger.log("Total Items: ${response.data?['total']}");
    Logger.log("Data Count: ${response.data?['data']?.length ?? 0}");
    Logger.log("---------------------------------");

    if (response.statusCode == 200 && response.data != null) {
      return SharePaginatedResponse.fromJson(response.data);
    } else {
      throw Exception('API returned status code ${response.statusCode}');
    }
  }

  Future<SharePaginatedResponse> fetchSharesWithSort({
    required int regionId,
    int page = 1,
    String sortBy = '',
    String sortDirection = '',
    String transactionType = '',
    String myPostsFirst = '',
  }) async {
    final Map<String, dynamic> queryParams = {
      'page': page,
      'region_id': regionId,
    };
    
    // Add sorting parameters if they're not empty
    if (sortBy.isNotEmpty) queryParams['sort_by'] = sortBy;
    if (sortDirection.isNotEmpty) queryParams['sort_direction'] = sortDirection;
    if (transactionType.isNotEmpty) queryParams['transaction_type'] = int.tryParse(transactionType) ?? transactionType;
    if (myPostsFirst.isNotEmpty) queryParams['my_posts_first'] = myPostsFirst;

    final response = await _dio.get('/share/sort', queryParameters: queryParams);

    Logger.log("------- Share Sort API Response -------");
    Logger.log("Status Code: ${response.statusCode}");
    Logger.log("URL: ${response.requestOptions.uri}");
    Logger.log("Sort Parameters: $queryParams");
    Logger.log("Current Page: ${response.data?['current_page']}");
    Logger.log("Total Items: ${response.data?['total']}");
    Logger.log("Data Count: ${response.data?['data']?.length ?? 0}");
    Logger.log("---------------------------------------");

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

  /// Fetch a single share by ID
  Future<Share?> fetchShareById(int shareId) async {
    final response = await _dio.get('/share/view/$shareId');

    Logger.log("------- Share Details API Response -------");
    Logger.log("Status Code: ${response.statusCode}");
    Logger.log("URL: ${response.requestOptions.uri}");
    Logger.log("Share ID: $shareId");
    Logger.log("-----------------------------------------");

    if (response.statusCode == 200 && response.data != null) {
      return Share.fromJson(response.data);
    } else {
      throw Exception('Failed to fetch share details: ${response.statusCode}');
    }
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

    Logger.log("------- Create Buy Share Response -------");
    Logger.log("Status Code: ${response.statusCode}");
    Logger.log("Response: ${response.data}");
    Logger.log("-----------------------------------------");

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

    Logger.log("------- Create Sell Share Response -------");
    Logger.log("Status Code: ${response.statusCode}");
    Logger.log("Response: ${response.data}");
    Logger.log("------------------------------------------");

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
    required String transactionType, // Add transaction_type parameter
  }) async {
    // Convert string transaction type to numeric: 1 for sell, 2 for buy
    final numericTransactionType = transactionType == 'sell' ? 1 : 2;
    
    final response = await _dio.post('/share/update/$shareId', data: {
      'region_id': regionId,
      'sector_id': sectorId,
      'quantity': quantity,
      'owner_name': ownerName,
      'price': price,
      'transaction_type': numericTransactionType, // Send numeric value
    });

    Logger.log("------- Update Share Response -------");
    Logger.log("Status Code: ${response.statusCode}");
    Logger.log("Response: ${response.data}");
    Logger.log("-------------------------------------");

    if (response.statusCode == 200) {
      return response.data ?? {};
    } else {
      throw Exception('API returned status code ${response.statusCode}');
    }
  }

  /// Search for shares with filters
  Future<SharePaginatedResponse> searchShares({
    String? id,
    int? regionId,
    int? sectorId,
    String? quantity,
    String? quantityOperator,
    int? transactionType, // 1 for sell, 2 for buy
    String? price,
    String? priceOperator,
    String? ownerName,
    int page = 1,
  }) async {
    final Map<String, dynamic> queryParameters = {'page': page};

    // Add filters to query parameters if they exist
    if (id != null && id.isNotEmpty) queryParameters['id'] = id;
    if (regionId != null) queryParameters['region_id'] = regionId;
    if (sectorId != null) queryParameters['sector_id'] = sectorId;
    if (quantity != null && quantity.isNotEmpty) queryParameters['quantity'] = quantity;
    if (quantityOperator != null && quantityOperator.isNotEmpty) queryParameters['quantity_operator'] = quantityOperator;
    if (transactionType != null) queryParameters['transaction_type'] = transactionType;
    if (price != null && price.isNotEmpty) queryParameters['price'] = price;
    if (priceOperator != null && priceOperator.isNotEmpty) queryParameters['price_operator'] = priceOperator;
    if (ownerName != null && ownerName.isNotEmpty) queryParameters['owner_name'] = ownerName;

    final response = await _dio.get('/share/search', queryParameters: queryParameters);

    Logger.log("------- Search Share Response -------");
    Logger.log("Status Code: ${response.statusCode}");
    Logger.log("URL: ${response.requestOptions.uri}");
    Logger.log("Query: $queryParameters");
    Logger.log("Total Items: ${response.data?['total']}");
    Logger.log("Data Count: ${response.data?['data']?.length ?? 0}");
    Logger.log("-------------------------------------");

    if (response.statusCode == 200 && response.data != null) {
      return SharePaginatedResponse.fromJson(response.data);
    } else {
      throw Exception('API returned status code ${response.statusCode}');
    }
  }

  /// Delete a share
  Future<Map<String, dynamic>> deleteShare(int shareId) async {
    try {
      final response = await _dio.delete('/share/delete/$shareId');

      if (response.statusCode == 200 && response.data != null) {
        Logger.log('Share deleted successfully: ${response.data}');
        return {
          'success': true,
          'message': response.data['message'] ?? 'Share deleted successfully',
        };
      } else {
        Logger.error('Failed to delete share, status: ${response.statusCode}');
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Failed to delete share',
        };
      }
    } on DioException catch (e) {
      Logger.error('Error deleting share', e.response?.data);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'An error occurred',
      };
    }
  }

  /// Close a share
  Future<Map<String, dynamic>> closeShare(int shareId) async {
    final response = await _dio.post('/share/close/$shareId');

    if (kDebugMode) {
      print("------- Close Share Response -------");
      print("Status Code: ${response.statusCode}");
      print("Response: ${response.data}");
      print("------------------------------------");
    }

    if (response.statusCode == 200) {
      return response.data ?? {};
    } else {
      throw Exception('API returned status code ${response.statusCode}');
    }
  }

  /// Get sectors grouped by region
  Future<Map<String, List<SectorOption>>> getSectorsGroupedByRegion() async {
    final response = await _dio.get('/sectors/grouped');

    if (response.statusCode == 200 && response.data != null) {
      final responseData = response.data['data'] as Map<String, dynamic>;
      final groupedSectors = responseData.map<String, List<SectorOption>>(
        (regionName, sectors) {
          final sectorList = (sectors as List)
              .map((sector) => SectorOption.fromJson(sector as Map<String, dynamic>))
              .toList();
          return MapEntry(regionName, sectorList);
        },
      );
      return groupedSectors;
    } else {
      throw Exception('Failed to load sectors');
    }
  }

  /// Get sector types
  Future<List<SectorTypeOption>> getSectorTypes() async {
    final response = await _dio.get('/sector-types');

    if (response.statusCode == 200 && response.data != null) {
      final responseData = response.data['data'] as List;
      return responseData
          .map((type) => SectorTypeOption.fromJson(type as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load sector types');
    }
  }

  /// Fetch sectors for a specific region
  Future<SectorResponse> fetchSectorsByRegion(int regionId) async {
    // Add a random query parameter to prevent caching
    final rand = DateTime.now().millisecondsSinceEpoch;
    final response = await _dio.get(
      '/sector/list/$regionId',
      queryParameters: {'rand': rand},
    );

    Logger.log("------- Sectors by Region API Response -------");
    Logger.log("Status Code: ${response.statusCode}");
    Logger.log("URL: ${response.requestOptions.uri}");
    Logger.log("Region ID: $regionId");
    Logger.log("---------------------------------------------");

    if (response.statusCode == 200 && response.data != null) {
      return SectorResponse.fromJson(response.data);
    } else {
      throw Exception('Failed to load sectors for region $regionId');
    }
  }

  /// Create buy request for a share (appointment scheduling)
  Future<Map<String, dynamic>> createBuyRequest(int shareId) async {
    try {
      final response = await _dio.post('/share/create_buy_request/$shareId');

      Logger.log("------- Create Buy Request Response -------");
      Logger.log("Status Code: ${response.statusCode}");
      Logger.log("URL: ${response.requestOptions.uri}");
      Logger.log("Share ID: $shareId");
      Logger.log("Response: ${response.data}");
      Logger.log("--------------------------------------------");

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': 'تم ترتيب الموعد بنجاح',
        };
      } else {
        Logger.error('Failed to create buy request, status: ${response.statusCode}');
        return {
          'success': false,
          'message': response.data?['message'] ?? 'فشل في ترتيب الموعد',
        };
      }
    } on DioException catch (e) {
      Logger.error('Error creating buy request', e.response?.data);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'حدث خطأ أثناء ترتيب الموعد',
      };
    }
  }

  /// Create sell request for a share (appointment scheduling)
  Future<Map<String, dynamic>> createSellRequest(int shareId) async {
    try {
      final response = await _dio.post('/share/create_sell_request/$shareId');

      Logger.log("------- Create Sell Request Response -------");
      Logger.log("Status Code: ${response.statusCode}");
      Logger.log("URL: ${response.requestOptions.uri}");
      Logger.log("Share ID: $shareId");
      Logger.log("Response: ${response.data}");
      Logger.log("---------------------------------------------");

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': 'تم ترتيب الموعد بنجاح',
        };
      } else {
        Logger.error('Failed to create sell request, status: ${response.statusCode}');
        return {
          'success': false,
          'message': response.data?['message'] ?? 'فشل في ترتيب الموعد',
        };
      }
    } on DioException catch (e) {
      Logger.error('Error creating sell request', e.response?.data);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'حدث خطأ أثناء ترتيب الموعد',
      };
    }
  }

  /// Cancel an order (appointment)
  Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    try {
      final response = await _dio.delete('/order/$orderId');

      Logger.log("------- Cancel Order Response -------");
      Logger.log("Status Code: ${response.statusCode}");
      Logger.log("URL: ${response.requestOptions.uri}");
      Logger.log("Order ID: $orderId");
      Logger.log("Response: ${response.data}");
      Logger.log("--------------------------------------");

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': 'تم إلغاء الموعد بنجاح',
        };
      } else {
        Logger.error('Failed to cancel order, status: ${response.statusCode}');
        return {
          'success': false,
          'message': response.data?['message'] ?? 'فشل في إلغاء الموعد',
        };
      }
    } on DioException catch (e) {
      Logger.error('Error cancelling order', e.response?.data);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'حدث خطأ أثناء إلغاء الموعد',
      };
    }
  }
}