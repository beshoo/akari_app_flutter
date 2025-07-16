import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../data/models/share_model.dart';
import '../data/models/apartment_model.dart';
import '../data/repositories/share_repository.dart';
import '../data/repositories/apartment_repository.dart';
import '../stores/auth_store.dart';
import '../services/secure_storage.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/post_card.dart';
import '../widgets/post_card_data.dart';
import '../widgets/custom_spinner.dart';
import 'share_form_page.dart';
import 'apartment_form_page.dart';
import 'search_page.dart';

class RegionPage extends StatefulWidget {
  final int? regionId;
  final String? regionName;
  final bool hasShare;
  final bool hasApartment;
  final int initialTabIndex;

  const RegionPage({
    super.key,
    this.regionId,
    this.regionName,
    required this.hasShare,
    required this.hasApartment,
    this.initialTabIndex = 0,
  });

  @override
  State<RegionPage> createState() => _RegionPageState();
}

class _RegionPageState extends State<RegionPage> with TickerProviderStateMixin {
  final ShareRepository _shareRepository = ShareRepository();
  final ApartmentRepository _apartmentRepository = ApartmentRepository();
  final ScrollController _scrollController = ScrollController();
  
  TabController? _tabController;
  final List<Widget> _tabs = [];
  
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
  bool hasLoadedShares = false;

  // Apartment state
  List<Apartment> apartments = [];
  bool isLoadingApartments = false;
  bool isLoadingMoreApartments = false;
  bool hasMoreApartmentPages = true;
  int currentApartmentPage = 1;
  String? apartmentErrorMessage;
  bool isRefreshingApartments = false;
  bool hasLoadedApartments = false;

  @override
  void initState() {
    super.initState();
    _buildTabs();
    
    if (_tabs.isNotEmpty) {
      _tabController = TabController(
        length: _tabs.length, 
        vsync: this,
        initialIndex: widget.initialTabIndex < _tabs.length ? widget.initialTabIndex : 0,
      );
      _tabController!.addListener(_onTabChanged);
    }
    
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialData();
      }
    });
  }
  
  void _buildTabs() {
    _tabs.clear();
    if (widget.hasShare) {
      _tabs.add(const Tab(text: 'الأسهم التنظيمية'));
    }
    if (widget.hasApartment) {
      _tabs.add(const Tab(text: 'العقارات'));
    }
  }

  void _loadInitialData() {
    if (widget.hasShare) {
      _sharesRefreshKey.currentState?.show();
    } else if (widget.hasApartment) {
      _apartmentsRefreshKey.currentState?.show();
    }
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
      if (mounted) {
        setState(() {
          _buildTabs();
        
          if (_tabs.isNotEmpty) {
            _tabController?.dispose();
            _tabController = TabController(length: _tabs.length, vsync: this);
            _tabController!.addListener(_onTabChanged);
          }
        });
      }

      // Clear the state for both tabs
      if (mounted) {
        setState(() {
          shares.clear();
          isLoadingShares = false;
          isLoadingMoreShares = false;
          hasMoreSharePages = true;
          currentSharePage = 1;
          shareErrorMessage = null;
          isRefreshingShares = false;
          hasLoadedShares = false;
          
          apartments.clear();
          isLoadingApartments = false;
          isLoadingMoreApartments = false;
          hasMoreApartmentPages = true;
          currentApartmentPage = 1;
          apartmentErrorMessage = null;
          isRefreshingApartments = false;
          hasLoadedApartments = false;
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadInitialData();
        }
      });
    }
  }

  void _onScroll() {
    // Trigger pagination when user is about 3 cards away from the end (85% of scroll)
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.85) {
      if (_tabController == null) {
        if (widget.hasShare) {
          if (!isLoadingMoreShares && hasMoreSharePages) _loadMoreShares();
        } else if (widget.hasApartment) {
          if (!isLoadingMoreApartments && hasMoreApartmentPages) _loadMoreApartments();
        }
        return;
      }
      
      final currentTabIndex = _tabController!.index;
      if (widget.hasShare && widget.hasApartment) {
        if (currentTabIndex == 0) {
          if (!isLoadingMoreShares && hasMoreSharePages) _loadMoreShares();
        } else {
          if (!isLoadingMoreApartments && hasMoreApartmentPages) _loadMoreApartments();
        }
      } else if (widget.hasShare) {
        if (!isLoadingMoreShares && hasMoreSharePages) _loadMoreShares();
      } else if (widget.hasApartment) {
        if (!isLoadingMoreApartments && hasMoreApartmentPages) _loadMoreApartments();
      }
    }
  }

  void _onTabChanged() {
    if (_tabController!.indexIsChanging) return;
    
    final currentTabIndex = _tabController!.index;
    
    if (widget.hasShare && widget.hasApartment) {
      if (currentTabIndex == 0) { // Shares
        if (shares.isEmpty && !isLoadingShares) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _sharesRefreshKey.currentState?.show();
          });
        }
      } else { // Apartments
        if (apartments.isEmpty && !isLoadingApartments) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _apartmentsRefreshKey.currentState?.show();
          });
        }
      }
    }
  }

  // Helper method to log auth data before each request
  Future<void> _logAuthData(String requestType) async {
    final authStore = Provider.of<AuthStore>(context, listen: false);
    final token = await SecureStorage.getToken();
    
    developer.log(
      '🔐 Auth Data for $requestType Request',
      name: 'AUTH_LOG',
      time: DateTime.now(),
    );
    
    developer.log(
      'User ID: ${authStore.userId ?? 'null'}\n'
      'Name: ${authStore.userName ?? 'null'}\n'
      'Phone: ${authStore.userPhone ?? 'null'}\n'
      'Privilege: ${authStore.userPrivilege ?? 'null'}\n'
      'Authenticated: ${authStore.isUserAuthenticated}\n'
      'Can Upload: ${authStore.canUpload}\n'
      'Token Type: ${authStore.tokenType ?? 'null'}\n'
      'Token Expires In: ${authStore.tokenExpiresIn ?? 'null'}\n'
      'Has Token: ${token != null}\n'
      'Token Length: ${token?.length ?? 0}\n'
      'Support Phone: ${authStore.supportPhone ?? 'null'}\n'
      'Show Ads Banner: ${authStore.showAdsBanner}\n'
      'Open For All: ${authStore.isOpenForAll}\n'
      'HTTP Error Log: ${authStore.httpErrorLog}\n'
      'Chat Enabled: ${authStore.chatEnabled}\n'
      'Region ID: ${widget.regionId ?? 'null'}\n'
      'Region Name: ${widget.regionName ?? 'null'}',
      name: 'AUTH_DETAILS',
    );
  }

  // Share methods
  Future<void> _loadShares({bool refresh = false}) async {
    if (widget.regionId == null) return;

    if (mounted) {
      setState(() {
        if (refresh) {
          isLoadingShares = true;
          shareErrorMessage = null;
          shares.clear();
          currentSharePage = 1;
          hasMoreSharePages = true;
        }
      });
    }

    try {
      // Log auth data before making the request
      await _logAuthData('Shares${refresh ? ' (Refresh)' : ''}');
      
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
          hasLoadedShares = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingShares = false;
          shareErrorMessage = e.toString();
          hasLoadedShares = true;
        });
      }
    }
  }

  Future<void> _loadMoreShares() async {
    if (widget.regionId == null || !hasMoreSharePages || isLoadingMoreShares) return;

    if (mounted) {
      setState(() {
        isLoadingMoreShares = true;
      });
    }

    try {
      currentSharePage++;
      
      // Log auth data before making the request
      await _logAuthData('Load More Shares (Page $currentSharePage)');
      
      final response = await _shareRepository.fetchShares(
        regionId: widget.regionId!,
        page: currentSharePage,
      );

      if (mounted) {
        setState(() {
          shares.addAll(response.shares);
          hasMoreSharePages = response.hasNextPage;
          isLoadingMoreShares = false;
          hasLoadedShares = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingMoreShares = false;
          currentSharePage--; // Revert page increment on error
          hasLoadedShares = true;
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
    if (mounted) {
      setState(() {
        isRefreshingShares = true;
        isLoadingShares = true;
      });
    }
    await _loadShares(refresh: true);
    if (mounted) {
      setState(() {
        isRefreshingShares = false;
      });
    }
  }

  // Apartment methods
  Future<void> _loadApartments({bool refresh = false}) async {
    if (widget.regionId == null) return;

    if (mounted) {
      setState(() {
        if (refresh) {
          isLoadingApartments = true;
          apartmentErrorMessage = null;
          apartments.clear();
          currentApartmentPage = 1;
          hasMoreApartmentPages = true;
        }
      });
    }

    try {
      // Log auth data before making the request
      await _logAuthData('Apartments${refresh ? ' (Refresh)' : ''}');
      
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
          hasLoadedApartments = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingApartments = false;
          apartmentErrorMessage = e.toString();
          hasLoadedApartments = true;
        });
      }
    }
  }

  Future<void> _loadMoreApartments() async {
    if (widget.regionId == null || !hasMoreApartmentPages || isLoadingMoreApartments) return;

    if (mounted) {
      setState(() {
        isLoadingMoreApartments = true;
      });
    }

    try {
      currentApartmentPage++;
      
      // Log auth data before making the request
      await _logAuthData('Load More Apartments (Page $currentApartmentPage)');
      
      final response = await _apartmentRepository.fetchApartments(
        regionId: widget.regionId!,
        page: currentApartmentPage,
      );

      if (mounted) {
        setState(() {
          apartments.addAll(response.apartments);
          hasMoreApartmentPages = response.hasNextPage;
          isLoadingMoreApartments = false;
          hasLoadedApartments = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingMoreApartments = false;
          currentApartmentPage--; // Revert page increment on error
          hasLoadedApartments = true;
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
    if (mounted) {
      setState(() {
        isRefreshingApartments = true;
        isLoadingApartments = true;
      });
    }
    await _loadApartments(refresh: true);
    if (mounted) {
      setState(() {
        isRefreshingApartments = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final List<Widget> tabViews = [];
    if (widget.hasShare) {
      tabViews.add(_buildSharesTab());
    }
    if (widget.hasApartment) {
      tabViews.add(_buildApartmentsTab());
    }

    if (_tabs.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F5F2),
        appBar: CustomAppBar(
          showBackButton: true,
          onBackPressed: () => Navigator.pop(context),
          onLogoPressed: () => Navigator.pop(context),
        ),
        body: Center(
          child: Text(
            'لا توجد بيانات متاحة لهذه المنطقة',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: CustomAppBar(
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        onLogoPressed: () => Navigator.pop(context),
        showAddAdButton: true,
        onAddAdPressed: () {
          // Check which tab is currently active and navigate accordingly
          if (_tabController != null && _tabs.length > 1) {
            // Multiple tabs - check current tab index
            final currentTabIndex = _tabController!.index;
            if (widget.hasShare && widget.hasApartment) {
              if (currentTabIndex == 0) {
                // Shares tab - navigate to share form
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShareFormPage(
                      mode: ShareFormMode.create,
                    ),
                  ),
                );
              } else {
                // Apartments tab - navigate to apartment form
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ApartmentFormPage(
                      mode: ApartmentFormMode.create,
                    ),
                  ),
                );
              }
            }
          } else if (_tabs.length == 1) {
            // Single tab - check which type it is
            if (widget.hasShare) {
              // Only shares available - navigate to share form
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShareFormPage(
                    mode: ShareFormMode.create,
                  ),
                ),
              );
            } else if (widget.hasApartment) {
              // Only apartments available - navigate to apartment form
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ApartmentFormPage(
                    mode: ApartmentFormMode.create,
                  ),
                ),
              );
            }
          }
        },
        onSearchPressed: () {
          // Determine which tab to open based on available services
          String? currentTab;
          if (widget.hasShare && widget.hasApartment) {
            // Both services available - check current tab
            if (_tabController != null) {
              currentTab = _tabController!.index == 0 ? 'shares' : 'apartments';
            } else {
              currentTab = 'shares'; // Default to shares
            }
          } else if (widget.hasShare) {
            currentTab = 'shares';
          } else if (widget.hasApartment) {
            currentTab = 'apartments';
          }
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchPage(
                regionId: widget.regionId,
                currentTab: currentTab,
              ),
            ),
          );
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
                if (_tabs.length > 1)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                        color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: Offset(0, 5), // Only bottom
                        spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: TabBar(
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
                          if (widget.hasShare && widget.hasApartment) {
                            if (index == 0) {
                              _sharesRefreshKey.currentState?.show();
                            } else {
                              _apartmentsRefreshKey.currentState?.show();
                            }
                          } else if (widget.hasShare) {
                             _sharesRefreshKey.currentState?.show();
                          } else if (widget.hasApartment) {
                            _apartmentsRefreshKey.currentState?.show();
                          }
                        }
                      },
                      tabs: _tabs,
                    ),
                  )
                else if (_tabs.length == 1)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 18,
                          offset: Offset(0, 8), // Only bottom
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Single tab - show it as a header with tap-to-refresh functionality
                        GestureDetector(
                          onTap: () {
                            if (widget.hasShare) {
                              _sharesRefreshKey.currentState?.show();
                            } else if (widget.hasApartment) {
                              _apartmentsRefreshKey.currentState?.show();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Center(
                              child: Text(
                                widget.hasShare ? 'الأسهم التنظيمية' : 'العقارات',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo',
                                  color: Color(0xFF633e3d),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFd7c1c0),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: (_tabs.length > 1)
              ? TabBarView(
                  controller: _tabController!,
                  children: tabViews,
                )
              : tabViews.first,
          ),
        ],
      ),
    );
  }

  Widget _buildSharesTab() {
    if (isLoadingShares && shares.isEmpty) {
      return const Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CustomSpinner(size: 40.0),
        ),
      );
    }



    if (shares.isEmpty && hasLoadedShares) {
      return RefreshIndicator(
        key: _sharesRefreshKey,
        onRefresh: _refreshShares,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'لا توجد أسهم متاحة في هذه المنطقة',
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
            ),
          ],
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
          if (mounted) {
            setState(() {
              // Additional safety check before updating
              if (index < shares.length) {
                shares[index] = updatedPost.share;
              }
            });
          }
        }
      },
    );
  }

  Widget _buildApartmentsTab() {
    if (isLoadingApartments && apartments.isEmpty) {
      return const Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CustomSpinner(size: 40.0),
        ),
      );
    }
    


    if (apartments.isEmpty && hasLoadedApartments) {
      return RefreshIndicator(
        key: _apartmentsRefreshKey,
        onRefresh: _refreshApartments,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'لا توجد عقارات متاحة في هذه المنطقة',
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
            ),
          ],
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
          if (mounted) {
            setState(() {
              // Additional safety check before updating
              if (index < apartments.length) {
                apartments[index] = updatedPost.apartment;
              }
            });
          }
        }
      },
    );
  }
} 