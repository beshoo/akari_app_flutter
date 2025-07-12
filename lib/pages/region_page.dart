import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models/share_model.dart';
import '../data/models/apartment_model.dart';
import '../data/repositories/share_repository.dart';
import '../data/repositories/apartment_repository.dart';
import '../stores/auth_store.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/post_card.dart';
import '../widgets/post_card_data.dart';
import '../widgets/custom_spinner.dart';

class RegionPage extends StatefulWidget {
  final int? regionId;
  final String? regionName;

  const RegionPage({
    super.key,
    this.regionId,
    this.regionName,
  });

  @override
  State<RegionPage> createState() => _RegionPageState();
}

class _RegionPageState extends State<RegionPage> with TickerProviderStateMixin {
  final ShareRepository _shareRepository = ShareRepository();
  final ApartmentRepository _apartmentRepository = ApartmentRepository();
  final ScrollController _scrollController = ScrollController();
  
  TabController? _tabController;
  
  // Global keys for refresh indicators
  final GlobalKey<RefreshIndicatorState> _sharesRefreshKey = GlobalKey<RefreshIndicatorState>();
  final GlobalKey<RefreshIndicatorState> _apartmentsRefreshKey = GlobalKey<RefreshIndicatorState>();
  
  // Share state
  List<Share> shares = [];
  bool isLoadingShares = false;
  bool isLoadingMoreShares = false;
  bool hasMoreSharePages = true;
  int currentSharePage = 1;
  String? shareErrorMessage;
  bool isRefreshingShares = false;
  bool showSharesNoDataMessage = false;

  // Apartment state
  List<Apartment> apartments = [];
  bool isLoadingApartments = false;
  bool isLoadingMoreApartments = false;
  bool hasMoreApartmentPages = true;
  int currentApartmentPage = 1;
  String? apartmentErrorMessage;
  bool isRefreshingApartments = false;
  bool showApartmentsNoDataMessage = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController!.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);

    // Simulate pull-to-refresh to load initial data. This shows the loading spinner.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _sharesRefreshKey.currentState?.show();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RegionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.regionId != oldWidget.regionId) {
      // When regionId changes, we should reload data.
      // Move to the first tab.
      _tabController?.animateTo(0);

      // Clear the state for the apartments tab so it reloads when selected.
      setState(() {
        apartments.clear();
        isLoadingApartments = false;
        isLoadingMoreApartments = false;
        hasMoreApartmentPages = true;
        currentApartmentPage = 1;
        apartmentErrorMessage = null;
        isRefreshingApartments = false;
        showApartmentsNoDataMessage = false;
      });

      // Show the refresh indicator on the shares tab to load new data.
      // This will also handle clearing the old shares data via _loadShares(refresh: true).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sharesRefreshKey.currentState?.show();
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.95) {
      if (_tabController!.index == 0) {
        // Shares tab
        if (!isLoadingMoreShares && hasMoreSharePages) {
          _loadMoreShares();
        }
      } else {
        // Apartments tab
        if (!isLoadingMoreApartments && hasMoreApartmentPages) {
          _loadMoreApartments();
        }
      }
    }
  }

  void _onTabChanged() {
    // This listener is called when the tab selection changes.
    // We only want to reload if the tab is selected, not during the transition.
    if (_tabController!.indexIsChanging) return;
    
    if (_tabController!.index == 0) {
      // Switched to shares tab
      if (shares.isEmpty && !isLoadingShares) {
        // Simulate pull-to-refresh when switching to shares tab
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _sharesRefreshKey.currentState?.show();
        });
      }
    } else if (_tabController!.index == 1) {
      // Switched to apartments tab
      if (apartments.isEmpty && !isLoadingApartments) {
        // Simulate pull-to-refresh when switching to apartments tab
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _apartmentsRefreshKey.currentState?.show();
        });
      }
    }
  }

  // Share methods
  Future<void> _loadShares({bool refresh = false}) async {
    if (widget.regionId == null) return;

    setState(() {
      if (refresh) {
        isLoadingShares = true;
        shareErrorMessage = null;
        shares.clear();
        currentSharePage = 1;
        hasMoreSharePages = true;
        showSharesNoDataMessage = false;
      }
    });

    // Start timer for showing no data message
    if (refresh) {
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && isLoadingShares && shares.isEmpty) {
          setState(() {
            showSharesNoDataMessage = true;
          });
        }
      });
    }

    try {
      final response = await _shareRepository.fetchShares(
        regionId: widget.regionId!,
        page: currentSharePage,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            shares = response.shares;
          } else {
            shares.addAll(response.shares);
          }
          
          hasMoreSharePages = response.hasNextPage;
          isLoadingShares = false;
          shareErrorMessage = null;
          showSharesNoDataMessage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingShares = false;
          shareErrorMessage = e.toString();
          showSharesNoDataMessage = false;
        });
      }
    }
  }

  Future<void> _loadMoreShares() async {
    if (widget.regionId == null || !hasMoreSharePages || isLoadingMoreShares) return;

    setState(() {
      isLoadingMoreShares = true;
    });

    try {
      currentSharePage++;
      final response = await _shareRepository.fetchShares(
        regionId: widget.regionId!,
        page: currentSharePage,
      );

      if (mounted) {
        setState(() {
          shares.addAll(response.shares);
          hasMoreSharePages = response.hasNextPage;
          isLoadingMoreShares = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingMoreShares = false;
          currentSharePage--; // Revert page increment on error
        });
        
        // Show error message for loading more
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحميل المزيد من الأسهم'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshShares() async {
    if (widget.regionId == null) return;
    setState(() {
      isRefreshingShares = true;
    });
    await _loadShares(refresh: true);
    setState(() {
      isRefreshingShares = false;
    });
  }

  // Apartment methods
  Future<void> _loadApartments({bool refresh = false}) async {
    if (widget.regionId == null) return;

    setState(() {
      if (refresh) {
        isLoadingApartments = true;
        apartmentErrorMessage = null;
        apartments.clear();
        currentApartmentPage = 1;
        hasMoreApartmentPages = true;
        showApartmentsNoDataMessage = false;
      }
    });

    // Start timer for showing no data message
    if (refresh) {
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && isLoadingApartments && apartments.isEmpty) {
          setState(() {
            showApartmentsNoDataMessage = true;
          });
        }
      });
    }

    try {
      final response = await _apartmentRepository.fetchApartments(
        regionId: widget.regionId!,
        page: currentApartmentPage,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            apartments = response.apartments;
          } else {
            apartments.addAll(response.apartments);
          }
          
          hasMoreApartmentPages = response.hasNextPage;
          isLoadingApartments = false;
          apartmentErrorMessage = null;
          showApartmentsNoDataMessage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingApartments = false;
          apartmentErrorMessage = e.toString();
          showApartmentsNoDataMessage = false;
        });
      }
    }
  }

  Future<void> _loadMoreApartments() async {
    if (widget.regionId == null || !hasMoreApartmentPages || isLoadingMoreApartments) return;

    setState(() {
      isLoadingMoreApartments = true;
    });

    try {
      currentApartmentPage++;
      final response = await _apartmentRepository.fetchApartments(
        regionId: widget.regionId!,
        page: currentApartmentPage,
      );

      if (mounted) {
        setState(() {
          apartments.addAll(response.apartments);
          hasMoreApartmentPages = response.hasNextPage;
          isLoadingMoreApartments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingMoreApartments = false;
          currentApartmentPage--; // Revert page increment on error
        });
        
        // Show error message for loading more
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحميل المزيد من العقارات'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshApartments() async {
    if (widget.regionId == null) return;
    setState(() {
      isRefreshingApartments = true;
    });
    await _loadApartments(refresh: true);
    setState(() {
      isRefreshingApartments = false;
    });
  }



  @override
  Widget build(BuildContext context) {
    // Ensure TabController is initialized
    _tabController ??= TabController(length: 2, vsync: this);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: CustomAppBar(
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        showAddAdButton: true,
        onAddAdPressed: () {
          // TODO: Handle "Add Ad" button press
        },
        onSearchPressed: () {
          // TODO: Handle search press
        },
        onSortPressed: () {
          // TODO: Handle sort press
        },
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFF7F5F2),
            child: Column(
              children: [
                if (widget.regionName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Center(
                      child: Text(
                        widget.regionName!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: Color(0xFF633e3d),
                        ),
                      ),
                    ),
                  ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFd7c1c0),
                ),
                TabBar(
                  controller: _tabController!,
                  labelColor: const Color(0xFF633e3d),
                  unselectedLabelColor: const Color(0xFF8C7A6A),
                  indicatorColor: const Color(0xFF633e3d),
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Cairo',
                  ),
                  onTap: (index) {
                    if (_tabController?.index == index) {
                      // User clicked on the currently active tab - simulate pull-to-refresh
                      if (index == 0) {
                        _sharesRefreshKey.currentState?.show();
                      } else if (index == 1) {
                        _apartmentsRefreshKey.currentState?.show();
                      }
                    }
                  },
                  tabs: const [
                    Tab(text: 'الأسهم التنظيمية'),
                    Tab(text: 'العقارات'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController!,
              children: [
                _buildSharesTab(), // الأسهم التنظيمية tab
                _buildApartmentsTab(), // العقارات tab
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharesTab() {
    if (shareErrorMessage != null) {
      return Center(
        child: RefreshIndicator(
          key: _sharesRefreshKey,
          onRefresh: _refreshShares,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'حدث خطأ في تحميل الأسهم',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    shareErrorMessage!,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _sharesRefreshKey.currentState?.show(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (shares.isEmpty) {
      return RefreshIndicator(
        key: _sharesRefreshKey,
        onRefresh: _refreshShares,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                if (showSharesNoDataMessage && !isLoadingShares) ...[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'لا توجد أسهم متاحة',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => _sharesRefreshKey.currentState?.show(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF633e3d),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'إعادة المحاولة',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      key: _sharesRefreshKey,
      onRefresh: _refreshShares,
      child: _buildShareList(),
    );
  }

  Widget _buildShareList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: shares.length + (hasMoreSharePages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == shares.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CustomSpinner(size: 32.0),
            ),
          );
        }
        
        // Safety check to prevent range errors
        if (index >= shares.length) {
          return const SizedBox.shrink();
        }
        
        return _buildShareItem(shares[index], index);
      },
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }

  Widget _buildShareItem(Share share, int index) {
    final authStore = Provider.of<AuthStore>(context, listen: false);
    final bool canShowOwner =
        authStore.userPrivilege == 'admin' || authStore.userPrivilege == 'owner';

    return PostCard(
      key: ValueKey('share_${share.id}'),
      postData: SharePostAdapter(share, showOwner: canShowOwner),
      scrollController: _scrollController,
      onPostUpdated: (updatedPost) {
        if (updatedPost is SharePostAdapter) {
          setState(() {
            // Additional safety check before updating
            if (index < shares.length) {
              shares[index] = updatedPost.share;
            }
          });
        }
      },
    );
  }

  Widget _buildApartmentsTab() {
    if (apartmentErrorMessage != null) {
      return Center(
        child: RefreshIndicator(
          key: _apartmentsRefreshKey,
          onRefresh: _refreshApartments,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'حدث خطأ في تحميل العقارات',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    apartmentErrorMessage!,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _apartmentsRefreshKey.currentState?.show(),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (apartments.isEmpty) {
      return RefreshIndicator(
        key: _apartmentsRefreshKey,
        onRefresh: _refreshApartments,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                if (showApartmentsNoDataMessage && !isLoadingApartments) ...[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'لا توجد عقارات متاحة',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => _apartmentsRefreshKey.currentState?.show(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF633e3d),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'إعادة المحاولة',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      key: _apartmentsRefreshKey,
      onRefresh: _refreshApartments,
      child: _buildApartmentList(),
    );
  }

  Widget _buildApartmentList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: apartments.length + (hasMoreApartmentPages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == apartments.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CustomSpinner(size: 32.0),
            ),
          );
        }
        
        // Safety check to prevent range errors
        if (index >= apartments.length) {
          return const SizedBox.shrink();
        }
        
        return _buildApartmentItem(apartments[index], index);
      },
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }

  Widget _buildApartmentItem(Apartment apartment, int index) {
    final authStore = Provider.of<AuthStore>(context, listen: false);
    final bool canShowOwner =
        authStore.userPrivilege == 'admin' || authStore.userPrivilege == 'owner';

    return PostCard(
      key: ValueKey('apartment_${apartment.id}'),
      postData: ApartmentPostAdapter(apartment, showOwner: canShowOwner),
      scrollController: _scrollController,
      onPostUpdated: (updatedPost) {
        if (updatedPost is ApartmentPostAdapter) {
          setState(() {
            // Additional safety check before updating
            if (index < apartments.length) {
              apartments[index] = updatedPost.apartment;
            }
          });
        }
      },
    );
  }
} 