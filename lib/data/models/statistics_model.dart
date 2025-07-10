import 'package:equatable/equatable.dart';

class ApartmentStatistic extends Equatable {
  final int id;
  final String name;
  final int apartmentsCount;

  const ApartmentStatistic({
    required this.id,
    required this.name,
    required this.apartmentsCount,
  });

  factory ApartmentStatistic.fromJson(Map<String, dynamic> json) {
    return ApartmentStatistic(
      id: json['id'],
      name: json['name'],
      apartmentsCount: json['apartments_count'],
    );
  }

  @override
  List<Object?> get props => [id, name, apartmentsCount];
}

class ShareStatistic extends Equatable {
  final int id;
  final String name;
  final int buySharesCount;
  final int sellSharesCount;
  final int totalShares;
  final dynamic averageSharePrice;

  const ShareStatistic({
    required this.id,
    required this.name,
    required this.buySharesCount,
    required this.sellSharesCount,
    required this.totalShares,
    this.averageSharePrice,
  });

  factory ShareStatistic.fromJson(Map<String, dynamic> json) {
    return ShareStatistic(
      id: json['id'],
      name: json['name'],
      buySharesCount: json['buy_shares_count'],
      sellSharesCount: json['sell_shares_count'],
      totalShares: json['total_shares'],
      averageSharePrice: json['average_share_price'],
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        buySharesCount,
        sellSharesCount,
        totalShares,
        averageSharePrice,
      ];
}

class StatisticsResponse extends Equatable {
  final List<ApartmentStatistic> apartmentStatistics;
  final List<ShareStatistic> shareStatistics;

  const StatisticsResponse({
    required this.apartmentStatistics,
    required this.shareStatistics,
  });

  factory StatisticsResponse.fromJson(Map<String, dynamic> json) {
    return StatisticsResponse(
      apartmentStatistics: (json['apartment_statistics'] as List)
          .map((i) => ApartmentStatistic.fromJson(i))
          .toList(),
      shareStatistics: (json['share_statistics'] as List)
          .map((i) => ShareStatistic.fromJson(i))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [apartmentStatistics, shareStatistics];
} 