import 'package:akari_app/data/models/region_model.dart';
import 'package:akari_app/data/models/statistics_model.dart';
import 'package:equatable/equatable.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeSuccess extends HomeState {
  final List<Region> regions;
  final List<ApartmentStatistic> apartmentStatistics;
  final List<ShareStatistic> shareStatistics;

  const HomeSuccess({
    required this.regions,
    required this.apartmentStatistics,
    required this.shareStatistics,
  });

  @override
  List<Object> get props => [regions, apartmentStatistics, shareStatistics];
}

class HomeFailure extends HomeState {
  final String message;

  const HomeFailure(this.message);

  @override
  List<Object> get props => [message];
} 