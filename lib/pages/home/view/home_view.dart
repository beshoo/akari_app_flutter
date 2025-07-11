import 'dart:io';
import 'package:akari_app/pages/home/bloc/home_bloc.dart';
import 'package:akari_app/pages/home/bloc/home_event.dart';
import 'package:akari_app/pages/home/bloc/home_state.dart';
import 'package:akari_app/pages/region_page.dart';
import 'package:akari_app/widgets/custom_app_bar.dart';
import 'package:akari_app/widgets/custom_dialog.dart';
import 'package:akari_app/widgets/custom_bottom_nav_bar.dart';
import 'package:akari_app/widgets/custom_fab.dart';
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
                onHelpPressed: () {},
                onNotificationPressed: () {},
                onSearchPressed: () {},
                onFavoritesPressed: () {},
              ),
              body: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state is HomeInitial || state is HomeLoading) {
                    return const Center(child: CircularProgressIndicator());
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
                                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                                  sliver: SliverGrid(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 13,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.85,
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
                                                ),
                                              ),
                                            );
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12.0),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                Image.asset(
                                                  'assets/images/city_1.jpg',
                                                  fit: BoxFit.cover,
                                                ),
                                                Positioned(
                                                  bottom: 0,
                                                  left: 0,
                                                  right: 0,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(12.0),
                                                    decoration: BoxDecoration(
                                                      color: const Color.fromARGB(153, 37, 37, 37),
                                                    ),
                                                    child: Text(
                                                      region.name,
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
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
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Column(
                                      children: [
                                        const Image(
                                          image: AssetImage('assets/images/stat.png'),
                                          height: 96,
                                          width: double.infinity,
                                          fit: BoxFit.contain,
                                        ),
                                        GridView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 13,
                                            mainAxisSpacing: 13,
                                            childAspectRatio: 1.2,
                                          ),
                                          itemCount: state.shareStatistics.length,
                                          itemBuilder: (context, index) {
                                            final item = state.shareStatistics[index];
                                            return _buildGradientCard(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Image.asset('assets/images/icons/building_1.png',
                                                      height: 48, width: 48, color: Colors.white),
                                                  Text('أسهم ${item.name}',
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white)),
                                                  Text('عدد إعلانات الشراء: ${item.buySharesCount}',
                                                      style: const TextStyle(fontSize: 12, color: Colors.white)),
                                                  Text('عدد إعلانات البيع: ${item.sellSharesCount}',
                                                      style: const TextStyle(fontSize: 12, color: Colors.white)),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 16),
                                        _buildGradientCard(
                                          height: 100,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Image.asset('assets/images/icons/updates.png',
                                                  height: 48, width: double.infinity, color: Colors.white),
                                              const Text('عدد العقارات المتاحة حسب النوع',
                                                  style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        GridView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 13,
                                            mainAxisSpacing: 13,
                                            childAspectRatio: 1.2,
                                          ),
                                          itemCount: state.apartmentStatistics.length,
                                          itemBuilder: (context, index) {
                                            final item = state.apartmentStatistics[index];
                                            return _buildGradientCard(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Image.asset('assets/images/icons/building_1.png',
                                                      height: 48, width: 48, color: Colors.white),
                                                  Text(item.name,
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white)),
                                                  Text(item.apartmentsCount.toString(),
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white)),
                                                ],
                                              ),
                                            );
                                          },
                                        ),

                                        const SizedBox(height: 16),
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
                // TODO: Navigate to add apartment page
              },
              onAddShare: () {
                // TODO: Navigate to add share page
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
} 