import 'package:akari_app/data/repositories/home_repository.dart';
import 'package:akari_app/pages/home/bloc/home_bloc.dart';
import 'package:akari_app/pages/home/bloc/home_event.dart';
import 'package:akari_app/pages/home/view/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(
        HomeRepository(),
      )..add(LoadHomeData()),
      child: const HomeView(),
    );
  }
} 