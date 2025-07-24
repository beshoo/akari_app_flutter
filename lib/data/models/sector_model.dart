import 'package:flutter/foundation.dart';

class Sector {
  final int id;
  final String code;
  final List<String> sectorPhotos;
  final int apartmentCount;
  final int shareCount;
  final String? description;
  final String? outerArea;
  final String? residentialArea;
  final String? commercialArea;
  final String? buildingArea;
  final String? floorsNumber;
  final String? totalFloorArea;
  final int sharesCount;
  final int apartmentsCount;
  final String? owners;
  final String? contractor;
  final String? engineers;

  Sector({
    required this.id,
    required this.code,
    required this.sectorPhotos,
    required this.apartmentCount,
    required this.shareCount,
    this.description,
    this.outerArea,
    this.residentialArea,
    this.commercialArea,
    this.buildingArea,
    this.floorsNumber,
    this.totalFloorArea,
    required this.sharesCount,
    required this.apartmentsCount,
    this.owners,
    this.contractor,
    this.engineers,
  });

  factory Sector.fromJson(Map<String, dynamic> json) {
    try {
      return Sector(
        id: json['id'] ?? 0,
        code: json['code'] ?? '',
        sectorPhotos: (json['sector_photos'] as List<dynamic>?)
            ?.map((photo) => photo.toString())
            .toList() ?? [],
        apartmentCount: json['apartment_count'] ?? 0,
        shareCount: json['share_count'] ?? 0,
        description: json['description'],
        outerArea: json['outer_area']?.toString(),
        residentialArea: json['residential_area']?.toString(),
        commercialArea: json['commercial_area']?.toString(),
        buildingArea: json['building_area']?.toString(),
        floorsNumber: json['floors_number']?.toString(),
        totalFloorArea: json['total_floor_area']?.toString(),
        sharesCount: json['shares_count'] ?? json['share_count'] ?? 0,
        apartmentsCount: json['apartments_count'] ?? json['apartment_count'] ?? 0,
        owners: json['owners'],
        contractor: json['contractor'],
        engineers: json['engineers'],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing Sector from JSON: $e');
        print('Problematic JSON: $json');
      }
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'sector_photos': sectorPhotos,
      'apartment_count': apartmentCount,
      'share_count': shareCount,
      'description': description,
      'outer_area': outerArea,
      'residential_area': residentialArea,
      'commercial_area': commercialArea,
      'building_area': buildingArea,
      'floors_number': floorsNumber,
      'total_floor_area': totalFloorArea,
      'shares_count': sharesCount,
      'apartments_count': apartmentsCount,
      'owners': owners,
      'contractor': contractor,
      'engineers': engineers,
    };
  }

  bool get hasApartments => apartmentsCount > 0;
  bool get hasShares => sharesCount > 0;
  bool get hasAdditionalInfo => 
    (description?.isNotEmpty ?? false) ||
    (outerArea?.isNotEmpty ?? false) ||
    (residentialArea?.isNotEmpty ?? false) ||
    (commercialArea?.isNotEmpty ?? false) ||
    (buildingArea?.isNotEmpty ?? false) ||
    (floorsNumber?.isNotEmpty ?? false) ||
    (totalFloorArea?.isNotEmpty ?? false) ||
    (contractor?.isNotEmpty ?? false) ||
    (engineers?.isNotEmpty ?? false);
}

class SectorType {
  final String key;
  final List<Sector> sectors;

  SectorType({
    required this.key,
    required this.sectors,
  });

  factory SectorType.fromJson(Map<String, dynamic> json) {
    try {
      return SectorType(
        key: json['key'] ?? '',
        sectors: (json['code'] as List<dynamic>?)
            ?.map((sectorJson) => Sector.fromJson(sectorJson as Map<String, dynamic>))
            .toList() ?? [],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing SectorType from JSON: $e');
        print('Problematic JSON: $json');
      }
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'code': sectors.map((sector) => sector.toJson()).toList(),
    };
  }
}

class SectorResponse {
  final List<SectorType> data;
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int from;
  final int to;

  SectorResponse({
    required this.data,
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.from,
    required this.to,
  });

  factory SectorResponse.fromJson(Map<String, dynamic> json) {
    try {
      return SectorResponse(
        data: (json['data'] as List<dynamic>?)
            ?.map((sectorTypeJson) => SectorType.fromJson(sectorTypeJson as Map<String, dynamic>))
            .toList() ?? [],
        total: json['total'] ?? 0,
        perPage: json['per_page'] ?? 20,
        currentPage: json['current_page'] ?? 1,
        lastPage: json['last_page'] ?? 1,
        from: json['from'] ?? 0,
        to: json['to'] ?? 0,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing SectorResponse from JSON: $e');
        print('Problematic JSON: $json');
      }
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((sectorType) => sectorType.toJson()).toList(),
      'total': total,
      'per_page': perPage,
      'current_page': currentPage,
      'last_page': lastPage,
      'from': from,
      'to': to,
    };
  }

  bool get hasNextPage => currentPage < lastPage;
  bool get isLastPage => currentPage >= lastPage;

  // Helper method to get all sectors from all types
  List<Sector> get allSectors {
    return data.expand((sectorType) => sectorType.sectors).toList();
  }

  // Helper method to get all unique sector codes
  List<String> get allSectorCodes {
    return allSectors.map((sector) => sector.code).toSet().toList()..sort();
  }

  // Helper method to get all sector type keys
  List<String> get sectorTypeKeys {
    return data.map((sectorType) => sectorType.key).toList();
  }
}

// Helper class for dropdown options
class SectorCodeOption {
  final String code;
  final String displayName;

  SectorCodeOption({
    required this.code,
    required this.displayName,
  });

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SectorCodeOption && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
} 