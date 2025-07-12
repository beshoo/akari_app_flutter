import 'package:dio/dio.dart';
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
    final response = await ApiService.instance.get('/apartment/$apartmentId');

    if (response.statusCode == 200) {
      return Apartment.fromJson(response.data);
    } else {
      throw Exception('Failed to fetch apartment: ${response.statusCode}');
    }
  }
} 