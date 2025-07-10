import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:akari_app/pages/home/bloc/home_event.dart';
import 'package:akari_app/pages/home/bloc/home_state.dart';
import 'package:akari_app/data/repositories/home_repository.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _homeRepository;

  HomeBloc(this._homeRepository) : super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    final isRefreshing = state is HomeSuccess;
    if (!isRefreshing) {
      emit(HomeLoading());
    }

    try {
      final results = await Future.wait([
        _homeRepository.fetchRegions(),
        _homeRepository.fetchStatistics(),
      ]);

      final regions = results[0] as List<dynamic>;
      final statistics = results[1] as dynamic;

      emit(HomeSuccess(
        regions: regions.cast(),
        apartmentStatistics: statistics.apartmentStatistics,
        shareStatistics: statistics.shareStatistics,
      ));
    } catch (e) {
      emit(HomeFailure(e.toString()));
    }
  }
}