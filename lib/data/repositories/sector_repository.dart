import 'package:dio/dio.dart';
import '../models/sector_model.dart';
import '../../services/api_service.dart';
import '../../utils/logger.dart';

class SectorRepository {
  final Dio _dio = ApiService.instance;

  /// Fetch sectors for a specific region with pagination
  Future<SectorResponse> fetchSectorsByRegion({
    required int regionId,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/sector/list/$regionId',
        queryParameters: {
          'page': page,
        },
      );

      Logger.log("------- Sector API Response -------");
      Logger.log("Status Code: ${response.statusCode}");
      Logger.log("URL: ${response.requestOptions.uri}");
      Logger.log("Region ID: $regionId");
      Logger.log("Page: $page");
      Logger.log("Current Page: ${response.data?['current_page']}");
      Logger.log("Total Items: ${response.data?['total']}");
      Logger.log("Data Count: ${response.data?['data']?.length ?? 0}");
      Logger.log("-----------------------------------");

      if (response.statusCode == 200 && response.data != null) {
        return SectorResponse.fromJson(response.data);
      } else {
        throw Exception('API returned status code ${response.statusCode}');
      }
    } on DioException catch (e) {
      Logger.error('Error fetching sectors by region', e.response?.data);
      throw Exception('Failed to fetch sectors: ${e.message}');
    }
  }

  /// Refresh sectors for a region (always start from page 1)
  Future<SectorResponse> refreshSectorsByRegion(int regionId) async {
    return fetchSectorsByRegion(regionId: regionId, page: 1);
  }

  /// Fetch a single sector by ID (if needed for detailed view)
  Future<Sector?> fetchSectorById(int sectorId) async {
    try {
      final response = await _dio.get('/sector/view/$sectorId');

      Logger.log("------- Sector Details API Response -------");
      Logger.log("Status Code: ${response.statusCode}");
      Logger.log("URL: ${response.requestOptions.uri}");
      Logger.log("Sector ID: $sectorId");
      Logger.log("-------------------------------------------");

      if (response.statusCode == 200 && response.data != null) {
        return Sector.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch sector details: ${response.statusCode}');
      }
    } on DioException catch (e) {
      Logger.error('Error fetching sector by ID', e.response?.data);
      return null; // Return null if sector not found
    }
  }

  /// Search sectors with filters (if API supports it)
  Future<SectorResponse> searchSectors({
    required int regionId,
    String? sectorCode,
    String? sectorType,
    int page = 1,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'region_id': regionId,
        'page': page,
      };

      // Add optional filters
      if (sectorCode != null && sectorCode.isNotEmpty) {
        queryParameters['code'] = sectorCode;
      }
      if (sectorType != null && sectorType.isNotEmpty) {
        queryParameters['type'] = sectorType;
      }

      final response = await _dio.get(
        '/sector/search',
        queryParameters: queryParameters,
      );

      Logger.log("------- Sector Search API Response -------");
      Logger.log("Status Code: ${response.statusCode}");
      Logger.log("URL: ${response.requestOptions.uri}");
      Logger.log("Search Parameters: $queryParameters");
      Logger.log("Total Items: ${response.data?['total']}");
      Logger.log("Data Count: ${response.data?['data']?.length ?? 0}");
      Logger.log("------------------------------------------");

      if (response.statusCode == 200 && response.data != null) {
        return SectorResponse.fromJson(response.data);
      } else {
        throw Exception('API returned status code ${response.statusCode}');
      }
    } on DioException catch (e) {
      Logger.error('Error searching sectors', e.response?.data);
      throw Exception('Failed to search sectors: ${e.message}');
    }
  }
} 