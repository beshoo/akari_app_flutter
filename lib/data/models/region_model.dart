import 'package:flutter/foundation.dart';

class Region {
  final int id;
  final String name;
  final bool active;
  final bool hasShare;
  final bool hasApartment;
  final num lowPrice;
  final num maxPrice;
  final String? createdAt;
  final String? updatedAt;

  Region({
    required this.id,
    required this.name,
    required this.active,
    required this.hasShare,
    required this.hasApartment,
    required this.lowPrice,
    required this.maxPrice,
    this.createdAt,
    this.updatedAt,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    try {
      return Region(
        id: json['id'],
        name: json['name'],
        active: json['active'] == 1,
        hasShare: json['has_share'] == 1,
        hasApartment: json['has_apartment'] == 1,
        lowPrice: json['low_price'],
        maxPrice: json['max_price'],
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing Region from JSON: $e');
        print('Problematic JSON: $json');
      }
      rethrow;
    }
  }
} 