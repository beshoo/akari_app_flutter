import '../models/apartment_model.dart';
import '../../services/api_service.dart';

class ApartmentRepository {
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
    final response = await ApiService.instance.get('/apartment/view/$apartmentId');

    if (response.statusCode == 200) {
      return Apartment.fromJson(response.data);
    } else {
      throw Exception('Failed to fetch apartment: ${response.statusCode}');
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
    int? floor,
    int? roomsCount,
    int? salonsCount,
    int? balconyCount,
    String? isTaras,
  }) async {
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
} 