import 'package:dio/dio.dart';

import '../models/apartment_model.dart';
import '../../services/api_service.dart';
import '../../utils/logger.dart';

class ApartmentRepository {
  final Dio _dio = ApiService.instance;

  Future<ApartmentResponse> fetchApartments({
    required int regionId,
    int page = 1,
  }) async {
    final response = await ApiService.instance.get(
      '/apartment/list/$regionId',
      queryParameters: {
        'page': page,
      },
    );

    if (response.statusCode == 200) {
      return ApartmentResponse.fromJson(response.data);
    } else {
      throw Exception('Failed to fetch apartments: ${response.statusCode}');
    }
  }

  Future<Apartment?> fetchApartmentById(int apartmentId) async {
    try {
      final response = await ApiService.instance.get('/apartment/view/$apartmentId');

      if (response.statusCode == 200) {
        return Apartment.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch apartment: ${response.statusCode}');
      }
    } on DioException catch (e) {
      Logger.error('Error fetching apartment by ID', e.response?.data);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createBuyApartment({
    required int regionId,
    required int sectorId,
    required int directionId,
    required int apartmentTypeId,
    required int paymentMethodId,
    required int apartmentStatusId,
    required int area,
    required String ownerName,
    required String price,
    required String equity,
    int? floor,
    int? roomsCount,
    int? salonsCount,
    int? balconyCount,
    String? isTaras,
  }) async {
    final response = await ApiService.instance.post(
      '/apartment/buy',
      data: {
        'region_id': regionId,
        'sector_id': sectorId,
        'direction_id': directionId,
        'apartment_type_id': apartmentTypeId,
        'payment_method_id': paymentMethodId,
        'apartment_status_id': apartmentStatusId,
        'area': area,
        'owner_name': ownerName,
        'price': double.tryParse(price) ?? 0.0,
        'equity': int.tryParse(equity) ?? 0,
        'floor': floor ?? 0,
        'rooms_count': roomsCount ?? 0,
        'salons_count': salonsCount ?? 0,
        'balcony_count': balconyCount ?? 0,
        'is_taras': isTaras ?? '0',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data;
    } else {
      throw Exception('Failed to create buy apartment: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createSellApartment({
    required int regionId,
    required int sectorId,
    required int directionId,
    required int apartmentTypeId,
    required int paymentMethodId,
    required int apartmentStatusId,
    required int area,
    required String ownerName,
    required String price,
    required String equity,
    int? floor,
    int? roomsCount,
    int? salonsCount,
    int? balconyCount,
    String? isTaras,
  }) async {
    final response = await ApiService.instance.post(
      '/apartment/sell',
      data: {
        'region_id': regionId,
        'sector_id': sectorId,
        'direction_id': directionId,
        'apartment_type_id': apartmentTypeId,
        'payment_method_id': paymentMethodId,
        'apartment_status_id': apartmentStatusId,
        'area': area,
        'owner_name': ownerName,
        'price': double.tryParse(price) ?? 0.0,
        'equity': int.tryParse(equity) ?? 0,
        'floor': floor ?? 0,
        'rooms_count': roomsCount ?? 0,
        'salons_count': salonsCount ?? 0,
        'balcony_count': balconyCount ?? 0,
        'is_taras': isTaras ?? '0',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.data;
    } else {
      throw Exception('Failed to create sell apartment: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updateApartment({
    required int apartmentId,
    required int regionId,
    required int sectorId,
    required int directionId,
    required int apartmentTypeId,
    required int paymentMethodId,
    required int apartmentStatusId,
    required int area,
    required String ownerName,
    required String price,
    required String equity,
    required String transactionType, // Add transaction_type parameter
    int? floor,
    int? roomsCount,
    int? salonsCount,
    int? balconyCount,
    String? isTaras,
  }) async {
    // Convert string transaction type to numeric: 1 for sell, 2 for buy
    final numericTransactionType = transactionType == 'sell' ? 1 : 2;
    
    final response = await ApiService.instance.post(
      '/apartment/update/$apartmentId',
      data: {
        'region_id': regionId,
        'sector_id': sectorId,
        'direction_id': directionId,
        'apartment_type_id': apartmentTypeId,
        'payment_method_id': paymentMethodId,
        'apartment_status_id': apartmentStatusId,
        'area': area,
        'owner_name': ownerName,
        'price': double.tryParse(price) ?? 0.0,
        'equity': int.tryParse(equity) ?? 0,
        'transaction_type': numericTransactionType, // Send numeric value
        'floor': floor ?? 0,
        'rooms_count': roomsCount ?? 0,
        'salons_count': salonsCount ?? 0,
        'balcony_count': balconyCount ?? 0,
        'is_taras': isTaras ?? '0',
      },
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to update apartment: ${response.statusCode}');
    }
  }

  Future<ApartmentResponse> searchApartments({
    int? id,
    int? regionId,
    int? sectorId,
    String? ownerName,
    int? directionId,
    int? apartmentTypeId,
    int? paymentMethodId,
    int? apartmentStatusId,
    String? area,
    String? floor,
    String? roomsCount,
    String? salonsCount,
    String? balconyCount,
    String? isTaras,
    String? equity,
    String? price,
    String? transactionType,
    String? priceOperator,
    String? equityOperator,
    int page = 1,
  }) async {
    final Map<String, dynamic> queryParameters = {
      'page': page,
    };
    if (id != null) queryParameters['id'] = id;
    if (regionId != null) queryParameters['region_id'] = regionId;
    if (sectorId != null) queryParameters['sector_id'] = sectorId;
    if (ownerName != null && ownerName.isNotEmpty) {
      queryParameters['owner_name'] = ownerName;
    }
    if (directionId != null) queryParameters['direction_id'] = directionId;
    if (apartmentTypeId != null) {
      queryParameters['apartment_type_id'] = apartmentTypeId;
    }
    if (paymentMethodId != null) {
      queryParameters['payment_method_id'] = paymentMethodId;
    }
    if (apartmentStatusId != null) {
      queryParameters['apartment_status_id'] = apartmentStatusId;
    }
    if (area != null && area.isNotEmpty) queryParameters['area'] = area;
    if (floor != null && floor.isNotEmpty) queryParameters['floor'] = floor;
    if (roomsCount != null && roomsCount.isNotEmpty) {
      queryParameters['rooms_count'] = roomsCount;
    }
    if (salonsCount != null && salonsCount.isNotEmpty) {
      queryParameters['salons_count'] = salonsCount;
    }
    if (balconyCount != null && balconyCount.isNotEmpty) {
      queryParameters['balcony_count'] = balconyCount;
    }
    if (isTaras != null && isTaras.isNotEmpty) {
      queryParameters['is_taras'] = isTaras;
    }
    if (equity != null && equity.isNotEmpty) queryParameters['equity'] = equity;
    if (price != null && price.isNotEmpty) queryParameters['price'] = price;
    if (transactionType != null && transactionType.isNotEmpty) {
      queryParameters['transaction_type'] = transactionType;
    }
    if (priceOperator != null) queryParameters['price_operator'] = priceOperator;
    if (equityOperator != null) {
      queryParameters['equity_operator'] = equityOperator;
    }

    final response = await ApiService.instance.get(
      '/apartment/search',
      queryParameters: queryParameters,
    );

    if (response.statusCode == 200) {
      return ApartmentResponse.fromJson(response.data);
    } else {
      throw Exception('Failed to search apartments: ${response.statusCode}');
    }
  }

  Future<List<ApartmentType>> fetchApartmentTypes() async {
    final response = await ApiService.instance.get('/apartment/types');

    if (response.statusCode == 200) {
      return (response.data as List)
          .map((item) => ApartmentType.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch apartment types: ${response.statusCode}');
    }
  }

  Future<List<ApartmentStatus>> fetchApartmentStatuses() async {
    final response = await ApiService.instance.get('/apartment_status');

    if (response.statusCode == 200) {
      return (response.data as List)
          .map((item) => ApartmentStatus.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch apartment statuses: ${response.statusCode}');
    }
  }

  Future<List<Direction>> fetchDirections() async {
    final response = await ApiService.instance.get('/direction');

    if (response.statusCode == 200) {
      return (response.data as List)
          .map((item) => Direction.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch directions: ${response.statusCode}');
    }
  }

  Future<List<PaymentMethod>> fetchPaymentMethods() async {
    final response = await ApiService.instance.get('/payment-methods');

    if (response.statusCode == 200) {
      return (response.data as List)
          .map((item) => PaymentMethod.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch payment methods: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> deleteApartment(int id) async {
    try {
      final response = await _dio.delete('/apartment/delete/$id');
      
      if (response.statusCode == 200 && response.data != null) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Apartment deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Failed to delete apartment',
        };
      }
    } on DioException catch (e) {
      Logger.error('Error deleting apartment', e.response?.data);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'An error occurred',
      };
    }
  }

  /// Create buy request for an apartment (appointment scheduling)
  Future<Map<String, dynamic>> createBuyRequest(int apartmentId) async {
    try {
      final response = await _dio.post('/apartment/create_buy_request/$apartmentId');

      Logger.log("------- Create Buy Request Response -------");
      Logger.log("Status Code: ${response.statusCode}");
      Logger.log("URL: ${response.requestOptions.uri}");
      Logger.log("Apartment ID: $apartmentId");
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

  /// Create sell request for an apartment (appointment scheduling)
  Future<Map<String, dynamic>> createSellRequest(int apartmentId) async {
    try {
      final response = await _dio.post('/apartment/create_sell_request/$apartmentId');

      Logger.log("------- Create Sell Request Response -------");
      Logger.log("Status Code: ${response.statusCode}");
      Logger.log("URL: ${response.requestOptions.uri}");
      Logger.log("Apartment ID: $apartmentId");
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