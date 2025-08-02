import 'package:akari_app/data/repositories/home_repository.dart';
import 'package:akari_app/pages/home/bloc/home_bloc.dart';
import 'package:akari_app/pages/home/bloc/home_event.dart';
import 'package:akari_app/pages/home/view/home_view.dart';
import 'package:akari_app/services/version_service.dart';
import 'package:akari_app/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _checkVersionIfPending();
  }

  void _checkVersionIfPending() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (VersionService.instance.hasPendingVersionCheck) {
        Logger.log('🔄 HomePage: Pending version check found, executing...');
        VersionService.instance.setPendingVersionCheck(false);
        await VersionService.instance.checkAndHandleVersionUpdate(context);
      }
    });
  }

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