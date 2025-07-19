import 'dart:io';

import 'package:akari_app/pages/apartment_form_page.dart';
import 'package:akari_app/pages/home/bloc/home_bloc.dart';
import 'package:akari_app/pages/home/bloc/home_event.dart';
import 'package:akari_app/pages/home/bloc/home_state.dart';
import 'package:akari_app/pages/region_page.dart';
import 'package:akari_app/pages/search_page.dart';
import 'package:akari_app/pages/search_results_page.dart';
import 'package:akari_app/pages/share_form_page.dart';
import 'package:akari_app/widgets/custom_app_bar.dart';
import 'package:akari_app/widgets/custom_bottom_nav_bar.dart';
import 'package:akari_app/widgets/custom_dialog.dart';
import 'package:akari_app/widgets/custom_fab.dart';
import 'package:akari_app/widgets/custom_spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedIndex = 0;

  void _handleApartmentStatisticsTap(int apartmentTypeId, String apartmentTypeName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(
          searchType: 'apartment',
          searchQuery: 'عقارات من نوع: $apartmentTypeName',
          originalSearchParams: {
            'apartmentTypeId': apartmentTypeId,
          },
        ),
      ),
    );
  }

  Future<void> _showExitDialog(BuildContext context) async {
    await showCustomDialog(
      context: context,
      title: 'الخروج من التطبيق',
      message: 'هل أنت متأكد من أنك تريد الخروج؟',
      cancelButtonText: 'إلغاء',
      onOkPressed: () {
        if (Platform.isAndroid) {
          SystemNavigator.pop();
        } else if (Platform.isIOS) {
          exit(0);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic _) async {
        if (didPop) {
          return;
        }
        _showExitDialog(context);
      },
      child: Container(
        color: const Color(0xFFF7F5F2),
        child: Stack(
          children: [
            Scaffold(
              extendBody: true,
              backgroundColor: Colors.transparent,
              appBar: CustomAppBar(
                showBackButton: true,
                onBackPressed: () => _showExitDialog(context),
                onFavoritesPressed: () {
                  // TODO: Handle favorites press
                },
                onSearchPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchPage(),
                    ),
                  );
                },
                onNotificationPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
                onHelpPressed: () {
                  // TODO: Handle help press
                },
              ),
              body: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state is HomeInitial || state is HomeLoading) {
                    return const Center(child: CustomSpinner(size: 50.0));
                  }
                  if (state is HomeFailure) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Failed to load data: ${state.message}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<HomeBloc>().add(LoadHomeData());
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is HomeSuccess) {
                    return Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "لا تضيع فرصة الاستثمار",
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "كل الوحدات متاحة, اختر الوحدة التي تناسبك",
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 16),
                              Image(
                                image: AssetImage('assets/images/akari_ai.png'),
                              ),
                              SizedBox(height: 16),
                            ],
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () {
                              final bloc = context.read<HomeBloc>();
                              bloc.add(LoadHomeData());
                              return bloc.stream.firstWhere((state) => state is! HomeLoading);
                            },
                            child: CustomScrollView(
                              slivers: [
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0),
                                  sliver: SliverGrid(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 0.88,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final region = state.regions[index];
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => RegionPage(
                                                  regionId: region.id,
                                                  regionName: region.name,
                                                  hasShare: region.hasShare,
                                                  hasApartment: region.hasApartment,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(18.0),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.15),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                  spreadRadius: 0,
                                                ),
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.08),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                  spreadRadius: 0,
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(18.0),
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  Image.asset(
                                                    'assets/images/city_1.jpg',
                                                    fit: BoxFit.cover,
                                                  ),
                                                  // Subtle gradient overlay for better text readability
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topCenter,
                                                        end: Alignment.bottomCenter,
                                                        colors: [
                                                          Colors.transparent,
                                                          Colors.black.withValues(alpha: 0.3),
                                                          Colors.black.withValues(alpha: 0.7),
                                                        ],
                                                        stops: const [0.0, 0.6, 1.0],
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    bottom: 0,
                                                    left: 0,
                                                    right: 0,
                                                    child: Container(
                                                      padding: const EdgeInsets.all(16.0),
                                                      child: Text(
                                                        region.name,
                                                        textAlign: TextAlign.center,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                          letterSpacing: -0.2,
                                                          shadows: [
                                                            Shadow(
                                                              color: Colors.black26,
                                                              offset: Offset(0, 1),
                                                              blurRadius: 2,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      childCount: state.regions.length,
                                    ),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                    child: Column(
                                      children: [
                                        // Stats header image with iOS-style spacing
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: const Image(
                                            image: AssetImage('assets/images/stat.png'),
                                            height: 100,
                                            width: double.infinity,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                       const SizedBox(height: 8),
                                        
                                        // Share statistics with iOS cards
                                        GridView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 16,
                                            childAspectRatio: 1.05,
                                          ),
                                          itemCount: state.shareStatistics.length,
                                          itemBuilder: (context, index) {
                                            final item = state.shareStatistics[index];
                                            return GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => RegionPage(
                                                      regionId: item.id, // Use id from ShareStatistic
                                                      regionName: item.name,
                                                      hasShare: true,
                                                      hasApartment: true,
                                                      initialTabIndex: 0, // Select shares tab
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: _buildIOSCard(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(10),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withValues(alpha: 0.25),
                                                        borderRadius: BorderRadius.circular(14),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withValues(alpha: 0.1),
                                                            blurRadius: 4,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Image.asset(
                                                        'assets/images/icons/building_1.png',
                                                        height: 30,
                                                        width: 30,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      'أسهم ${item.name}',
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                        letterSpacing: -0.2,
                                                        shadows: [
                                                          Shadow(
                                                            color: Colors.black26,
                                                            offset: Offset(0, 1),
                                                            blurRadius: 2,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      'طلبات الشراء: ${item.buySharesCount}',
                                                      style: TextStyle(
                                                        fontSize: 17,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.white.withValues(alpha: 0.95),
                                                        letterSpacing: -0.1,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      'عروض البيع: ${item.sellSharesCount}',
                                                      style: TextStyle(
                                                        fontSize: 17,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.white.withValues(alpha: 0.95),
                                                        letterSpacing: -0.1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        
                                        const SizedBox(height: 24),
                                        
                                                                                // Section header card
                                        _buildIOSHeaderCard(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.25),
                                                  borderRadius: BorderRadius.circular(14),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.1),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Image.asset(
                                                  'assets/images/icons/updates.png',
                                                  height: 26,
                                                  width: 26,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'عدد العقارات المتاحة حسب النوع',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: -0.3,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black26,
                                                      offset: Offset(0, 1),
                                                      blurRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        const SizedBox(height: 20),
                                        
                                        // Apartment statistics with iOS cards
                                        GridView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 16,
                                            childAspectRatio: 1.05,
                                          ),
                                          itemCount: state.apartmentStatistics.length,
                                          itemBuilder: (context, index) {
                                            final item = state.apartmentStatistics[index];
                                            return GestureDetector(
                                              onTap: () {
                                                _handleApartmentStatisticsTap(item.id, item.name);
                                              },
                                              child: _buildIOSCard(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(10),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withValues(alpha: 0.25),
                                                        borderRadius: BorderRadius.circular(14),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withValues(alpha: 0.1),
                                                            blurRadius: 4,
                                                            offset: const Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Image.asset(
                                                        'assets/images/icons/building_1.png',
                                                        height: 30,
                                                        width: 30,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      item.name,
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(
                                                        fontSize: 17,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                        letterSpacing: -0.2,
                                                        shadows: [
                                                          Shadow(
                                                            color: Colors.black26,
                                                            offset: Offset(0, 1),
                                                            blurRadius: 2,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      item.apartmentsCount.toString(),
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(
                                                        fontSize: 26,
                                                       // fontWeight: FontWeight.w700,
                                                        color: Colors.white,
                                                        letterSpacing: -0.5,
                                                        shadows: [
                                                          Shadow(
                                                            color: Colors.black26,
                                                            offset: Offset(0, 1),
                                                            blurRadius: 2,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),

                                        const SizedBox(height: 24),
                                        // Add extra bottom padding for FAB
                                        const SizedBox(height: 150),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return Container();
                },
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 25, // Matches the bottom margin of the nav bar
                color: const Color(0xFFF7F5F2), // The screen's background color
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: CustomBottomNavBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
            ),
            CustomFAB(
              onAddApartment: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ApartmentFormPage(
                      mode: ApartmentFormMode.create,
                    ),
                  ),
                );
              },
              onAddShare: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShareFormPage(
                      mode: ShareFormMode.create,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientCard({required Widget child, double? height}) {
    const colors = [
      Color(0xFF633e3d),
      Color(0xFF774b46),
      Color(0xFF8d5e52),
      Color(0xFFa47764),
      Color(0xFFbda28c)
    ];

    return Container(
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }

  Widget _buildIOSCard({required Widget child, double? height}) {
    const colors = [
      Color(0xFF633e3d),
      Color(0xFF774b46),
      Color(0xFF8d5e52),
      Color(0xFFa47764),
      Color(0xFFbda28c)
    ];

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildIOSHeaderCard({required Widget child, double? height}) {
    const colors = [
      Color(0xFF633e3d),
      Color(0xFF774b46),
      Color(0xFF8d5e52),
      Color(0xFFa47764),
      Color(0xFFbda28c)
    ];

    return Container(
      width: double.infinity,
      height: height ?? 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: child,
      ),
    );
  }
} 