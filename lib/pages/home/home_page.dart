import 'package:akari_app/data/repositories/home_repository.dart';
import 'package:akari_app/pages/home/bloc/home_bloc.dart';
import 'package:akari_app/pages/home/bloc/home_event.dart';
import 'package:akari_app/pages/home/view/home_view.dart';
import 'package:akari_app/services/version_service.dart';
import 'package:akari_app/stores/auth_store.dart';
import 'package:akari_app/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

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
    _loadUserData();
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

  void _loadUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authStore = Provider.of<AuthStore>(context, listen: false);
      
      // Check if user data is already loaded
      if (authStore.user == null || authStore.user!.isEmpty) {
        Logger.log('🔄 HomePage: User data not loaded, calling checkAuthStatus...');
        try {
          await authStore.checkAuthStatus();
          Logger.log('✅ HomePage: User data loaded successfully');
        } catch (e) {
          Logger.error('❌ HomePage: Failed to load user data', e);
          // Don't show error to user as this is background loading
        }
      } else {
        Logger.log('✅ HomePage: User data already loaded, skipping HTTP call');
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