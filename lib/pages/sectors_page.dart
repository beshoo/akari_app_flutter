import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shimmer/shimmer.dart';
import '../data/models/region_model.dart';
import '../data/models/sector_model.dart';
import '../data/repositories/home_repository.dart';
import '../data/repositories/sector_repository.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_sheet.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dropdown_type_text_support.dart';
import '../widgets/custom_spinner.dart';
import '../utils/logger.dart';
import 'search_results_page.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class SectorsPage extends StatefulWidget {
  final int? initialRegionId;
  final String? initialSectorType;

  const SectorsPage({
    super.key,
    this.initialRegionId,
    this.initialSectorType,
  });

  @override
  State<SectorsPage> createState() => _SectorsPageState();
}

class _SectorsPageState extends State<SectorsPage> with TickerProviderStateMixin {
  final HomeRepository _homeRepository = HomeRepository();
  final SectorRepository _sectorRepository = SectorRepository();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  // Tab controllers
  late TabController _regionTabController;
  TabController? _sectorTypeTabController;

  // Page controllers for image carousels
  final Map<int, PageController> _pageControllers = {};
  final Map<int, int> _currentPages = {};

  // Data
  List<Region> _regions = [];
  SectorResponse? _sectorResponse;
  List<Sector> _filteredSectors = [];

  // --- Caching ---
  final Map<int, SectorResponse> _sectorCache = {}; // regionId -> SectorResponse
  final Map<int, int> _sectorPageCache = {}; // regionId -> last loaded page

  // State management
  bool _isInitialLoading = false;
  bool _isLoadingMoreSectors = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMorePages = true;

  // Selected values
  Region? _selectedRegion;
  String? _selectedSectorType;
  SectorCodeOption? _selectedSectorCode;

  // Dropdown options
  List<SectorCodeOption> _sectorCodeOptions = [];

  // Bottom sheet state
  bool _isBottomSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _regionTabController.dispose();
    _sectorTypeTabController?.dispose();
    // Dispose all page controllers
    for (var controller in _pageControllers.values) {
      controller.dispose();
    }
    // Clear cache on dispose
    _sectorCache.clear();
    _sectorPageCache.clear();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreSectors();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
    });

    try {
      await _loadRegions();
      if (_regions.isNotEmpty) {
        final initialRegion = widget.initialRegionId != null
            ? _regions.firstWhere((r) => r.id == widget.initialRegionId,
                orElse: () => _regions.first)
            : _regions.first;
        await _selectRegion(initialRegion);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في تحميل البيانات: ${e.toString()}';
      });
      Logger.error('Error loading initial data', e);
    } finally {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadRegions() async {
    final regions = await _homeRepository.fetchRegions();
    
    setState(() {
      _regions = regions.where((region) => region.active).toList();
    });

    if (_regions.isNotEmpty) {
      _regionTabController = TabController(length: _regions.length, vsync: this);
      _regionTabController.addListener(_onRegionTabChanged);
    }
  }

  void _onRegionTabChanged() {
    if (!_regionTabController.indexIsChanging) {
      final selectedRegion = _regions[_regionTabController.index];
      // Defer the state update until after the build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _selectRegion(selectedRegion);
        // Scroll to top after switching region
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _selectRegion(Region region) async {
    setState(() {
      _selectedRegion = region;
      _selectedSectorType = null;
      _selectedSectorCode = null;
      _sectorResponse = null;
      _filteredSectors = [];
      _sectorCodeOptions = [];
      _currentPage = 1;
      _hasMorePages = true;
    });

    // Dispose previous sector type tab controller
    _sectorTypeTabController?.dispose();
    _sectorTypeTabController = null;

    // Use cache if available
    if (_sectorCache.containsKey(region.id)) {
      setState(() {
        _sectorResponse = _sectorCache[region.id];
        _currentPage = _sectorPageCache[region.id] ?? 1;
        _hasMorePages = _sectorResponse!.hasNextPage;
      });
      _setupSectorTypeTabs();
      _updateSectorCodeOptions();
      _applyFilters();
    } else {
      await _loadSectors(refresh: true);
    }
  }

  void _onSectorTypeTabChanged() {
    if (_sectorTypeTabController != null && !_sectorTypeTabController!.indexIsChanging) {
      final sectorTypes = _sectorResponse?.sectorTypeKeys ?? [];
      if (_sectorTypeTabController!.index < sectorTypes.length) {
        // Defer the state update until after the build is complete
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _selectedSectorType = sectorTypes[_sectorTypeTabController!.index];
            // Don't clear the selected sector code when tab changes manually
            // Only clear it when a new region is selected
            // _selectedSectorCode = null;
          });
          _applyFilters();
          // Scroll to top after switching sector type
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  Future<void> _loadSectors({bool refresh = false}) async {
    if (_selectedRegion == null) return;
    final regionId = _selectedRegion!.id;

    if (!refresh) {
      setState(() {
        _isLoadingMoreSectors = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _sectorRepository.fetchSectorsByRegion(
        regionId: regionId,
        page: _currentPage,
      );

      setState(() {
        if (refresh || !_sectorCache.containsKey(regionId)) {
          _sectorResponse = response;
          _sectorCache[regionId] = response;
          _sectorPageCache[regionId] = response.currentPage;
          _currentPage = 1;
          _hasMorePages = true;
        } else {
          // Merge with existing data for pagination
          final existing = _sectorCache[regionId]!;
          final existingData = existing.data;
          final newData = response.data;
          for (final newSectorType in newData) {
            final existingTypeIndex = existingData.indexWhere((existing) => existing.key == newSectorType.key);
            if (existingTypeIndex >= 0) {
              existingData[existingTypeIndex].sectors.addAll(newSectorType.sectors);
            } else {
              existingData.add(newSectorType);
            }
          }
          _sectorResponse = SectorResponse(
            data: existingData,
            total: response.total,
            perPage: response.perPage,
            currentPage: response.currentPage,
            lastPage: response.lastPage,
            from: response.from,
            to: response.to,
          );
          _sectorCache[regionId] = _sectorResponse!;
          _sectorPageCache[regionId] = response.currentPage;
          _isLoadingMoreSectors = false;
        }
        _hasMorePages = response.hasNextPage;
        _setupSectorTypeTabs();
        _updateSectorCodeOptions();
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        if (!refresh) {
          _isLoadingMoreSectors = false;
          _currentPage--; // Revert page increment on error
        }
      });
      Logger.error('Error loading sectors', e);
      rethrow; // Re-throw to be caught by _loadInitialData
    }
  }

  Future<void> _loadMoreSectors() async {
    if (!_hasMorePages || _isLoadingMoreSectors) return;
    _currentPage++;
    // Only fetch if not already cached
    final regionId = _selectedRegion?.id;
    if (regionId != null && _sectorPageCache[regionId] != null && _currentPage <= _sectorPageCache[regionId]!) {
      // Already cached, just update state
      setState(() {
        _sectorResponse = _sectorCache[regionId];
      });
      _setupSectorTypeTabs();
      _updateSectorCodeOptions();
      _applyFilters();
      return;
    }
    await _loadSectors(refresh: false);
  }

  void _setupSectorTypeTabs() {
    if (_sectorResponse?.data.isNotEmpty ?? false) {
      final sectorTypes = _sectorResponse!.sectorTypeKeys;
      
      _sectorTypeTabController?.dispose();
      _sectorTypeTabController = TabController(length: sectorTypes.length, vsync: this);
      _sectorTypeTabController!.addListener(_onSectorTypeTabChanged);
      
      // Set initial sector type based on parameter or first available
      if (widget.initialSectorType != null && sectorTypes.contains(widget.initialSectorType)) {
        final index = sectorTypes.indexOf(widget.initialSectorType!);
        _sectorTypeTabController!.index = index;
        _selectedSectorType = widget.initialSectorType;
      } else if (sectorTypes.isNotEmpty) {
        _selectedSectorType = sectorTypes.first;
      }
    }
  }

  void _updateSectorCodeOptions() {
    if (_sectorResponse != null) {
      final codes = _sectorResponse!.allSectorCodes;
      setState(() {
        _sectorCodeOptions = codes.map((code) => 
          SectorCodeOption(code: code, displayName: code)
        ).toList();
        
        // Sort options by code number
        _sectorCodeOptions.sort((a, b) {
          final aCode = int.tryParse(a.code) ?? 0;
          final bCode = int.tryParse(b.code) ?? 0;
          return aCode.compareTo(bCode);
        });
      });
    }
  }

  void _applyFilters() {
    if (_sectorResponse == null) return;

    List<Sector> sectors = [];
    
    // Filter by sector type
    if (_selectedSectorType != null) {
      final sectorType = _sectorResponse!.data.firstWhere(
        (type) => type.key == _selectedSectorType,
        orElse: () => SectorType(key: '', sectors: []),
      );
      sectors = List.from(sectorType.sectors);
    } else {
      sectors = _sectorResponse!.allSectors;
    }

    // Filter by sector code - show only selected code when one is chosen
    if (_selectedSectorCode != null) {
      sectors = sectors.where((sector) => sector.code == _selectedSectorCode!.code).toList();
    } else {
      // Sort sectors by code number (A to Z) when no specific code is selected
      sectors.sort((a, b) {
        final aCode = int.tryParse(a.code) ?? 0;
        final bCode = int.tryParse(b.code) ?? 0;
        return aCode.compareTo(bCode);
      });
    }

    setState(() {
      _filteredSectors = sectors;
    });
  }

  Future<void> _refreshSectors() async {
    if (_selectedRegion != null) {
      try {
        await _loadSectors(refresh: true);
      } catch (e) {
        setState(() {
          _errorMessage = 'فشل في تحديث المقاسم: ${e.toString()}';
        });
      }
    }
  }

  void _onSectorCodeChanged(SectorCodeOption? option) {
    setState(() {
      _selectedSectorCode = option;
    });

    if (option != null) {
      // Find which sector type contains this code
      String? targetSectorType;
      for (final sectorType in _sectorResponse?.data ?? []) {
        if (sectorType.sectors.any((sector) => sector.code == option.code)) {
          targetSectorType = sectorType.key;
          break;
        }
      }

      // Switch to the correct tab if found
      if (targetSectorType != null && _sectorTypeTabController != null) {
        final sectorTypes = _sectorResponse?.sectorTypeKeys ?? [];
        final targetIndex = sectorTypes.indexOf(targetSectorType);
        if (targetIndex >= 0 && targetIndex != _sectorTypeTabController!.index) {
          // Defer the tab animation and state update
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _sectorTypeTabController!.animateTo(targetIndex);
            setState(() {
              _selectedSectorType = targetSectorType;
            });
          });
        }
      }
    }

    _applyFilters();
    
    // Scroll to top when filter changes
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showSectorBottomSheet(Sector sector) {
    setState(() {
      _isBottomSheetOpen = true;
    });

    showMaterialModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSectorBottomSheet(sector),
    ).then((_) {
      setState(() {
        _isBottomSheetOpen = false;
      });
    });
  }

  void _showSectorInfoBottomSheet(Sector sector) {
    showMaterialModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSectorInfoBottomSheet(sector),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isBottomSheetOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (_isBottomSheetOpen && !didPop) {
          Navigator.of(context).pop();
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF7F5F2),
          appBar: const CustomAppBar(
            showBackButton: true,
            showLogo: true,
            showNotificationButton: true,
                    showFavoritesButton: true,
                    showSearchButton: true,
                    showHelpButton: true,

          ),
          body: SafeArea(
            child: _buildBody(),
          ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: 3, // Sectors tab index
            onTap: (index) {
              // Optionally handle navigation if needed
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return const Center(child: CustomSpinner(size: 50.0));
    }

    if (_errorMessage != null && _regions.isEmpty) {
      return _buildErrorWidget();
    }

    return Column(
      children: [
        _buildRegionTabs(),
        if (_sectorTypeTabController != null) _buildSectorTypeTabs(),
        _buildSectorCodeDropdown(),
        Expanded(child: _buildSectorsList()),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'حدث خطأ غير متوقع',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              title: 'إعادة المحاولة',
              onPressed: _loadInitialData,
              hasGradient: true,
              textColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionTabs() {
    if (_regions.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: Container(
        height: 50,
        decoration: const BoxDecoration(
          color: Color(0xFFF7F5F2),
          border: Border(
            bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
          ),
        ),
        child: _regions.length <= 3
            ? Center(
                child: TabBar(
                  controller: _regionTabController,
                  isScrollable: false,
                  labelColor: const Color(0xFF633e3d),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF633e3d),
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Cairo',
                  ),
                  tabs: _regions.map((region) => Tab(text: region.name)).toList(),
                ),
              )
            : TabBar(
                controller: _regionTabController,
                isScrollable: true,
                labelColor: const Color(0xFF633e3d),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF633e3d),
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Cairo',
                ),
                tabs: _regions.map((region) => Tab(text: region.name)).toList(),
              ),
      ),
    );
  }

  Widget _buildSectorTypeTabs() {
    if (_sectorTypeTabController == null || _sectorResponse?.data.isEmpty == true) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: Container(
        height: 50,
        decoration: const BoxDecoration(
          color: Color(0xFFF7F5F2),
          border: Border(
            bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
          ),
        ),
        child: TabBar(
          controller: _sectorTypeTabController!,
          isScrollable: ((_sectorResponse?.sectorTypeKeys.length ?? 0) > 3) ? true : false,
          labelColor: const Color(0xFF8C7A6A),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF8C7A6A),
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            fontFamily: 'Cairo',
          ),
          // No tabAlignment needed for centered tabs when isScrollable is false
          tabs: (_sectorResponse?.sectorTypeKeys ?? []).map((type) => Tab(text: type)).toList(),
        ),
      ),
    );
  }

  Widget _buildSectorCodeDropdown() {
    return Container(
      key: const ValueKey('sector_code_dropdown'),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F5F2),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      child: CustomDropdownTypeTextSupport<SectorCodeOption>(
        key: const ValueKey('sector_dropdown_widget'),
        value: _selectedSectorCode,
        items: _sectorCodeOptions,
        itemLabel: (option) => option.displayName,
        itemValue: (option) => option.code,
        onChanged: _onSectorCodeChanged,
        hintText: 'البحث برقم المقسم',
        labelText: 'ترتيب حسب رقم المقسم',
        emptyMessage: 'لا توجد مقاسم متاحة',
        searchHintText: 'ابحث عن رقم المقسم...',
      ),
    );
  }

  Widget _buildSectorsList() {
    if (_filteredSectors.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _refreshSectors,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _filteredSectors.length + (_isLoadingMoreSectors ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _filteredSectors.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CustomSpinner(size: 30.0)),
            );
          }
          return _buildSectorCard(_filteredSectors[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/no_data.png',
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد مقاسم متاحة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedSectorCode != null
                  ? 'لا توجد مقاسم بالرقم المحدد'
                  : 'لا توجد مقاسم في هذه المنطقة',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorCard(Sector sector) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 350,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF1F2937).withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(45, 0, 0, 0),
                  offset: const Offset(0, 5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImageCarouselOnly(sector),
            ),
          ),
          if (sector.sectorPhotos.length > 1) ...[
            const SizedBox(height: 8),
            _buildDotsIndicatorExternal(sector),
          ],
        ],
      ),
    );
  }


  Widget _buildImageCarouselOnly(Sector sector) {
    if (sector.sectorPhotos.isEmpty) {
      return _buildPlaceholderImageOnly(sector);
    }

    // Get or create page controller for this sector
    if (!_pageControllers.containsKey(sector.id)) {
      _pageControllers[sector.id] = PageController();
      _currentPages[sector.id] = 0;
    }

    return SizedBox(
      height: 350,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageControllers[sector.id],
            itemCount: sector.sectorPhotos.length,
            onPageChanged: (index) {
              setState(() {
                _currentPages[sector.id] = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showSectorBottomSheet(sector),
                child: CachedNetworkImage(
                  imageUrl: sector.sectorPhotos[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CustomSpinner(size: 30.0)),
                  ),
                  errorWidget: (context, url, error) => _buildPlaceholderImageOnly(sector),
                ),
              );
            },
          ),
          _buildImageOverlay(sector),
        ],
      ),
    );
  }


  Widget _buildPlaceholderImageOnly(Sector sector) {
    return GestureDetector(
      onTap: () => _showSectorBottomSheet(sector),
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          color: Colors.grey[200],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/no_photo.jpg',
              height: 80,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            const Text(
              'لا توجد صور متاحة',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOverlay(Sector sector) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 80,
          maxHeight: 150,
        ),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color.fromARGB(219, 71, 47, 45),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'المقسم رقم ${sector.code}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildOverlayInfo(
                  'assets/images/icons/building_1.png',
                  '${sector.apartmentsCount} عقار',
                ),
                const SizedBox(width: 16),
                _buildOverlayInfo(
                  'assets/images/icons/gold.png',
                  '${sector.sharesCount} سهم',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayInfo(String iconPath, String text) {
    return Row(
      children: [
        Image.asset(
          iconPath,
          width: 16,
          height: 16,
          color: Colors.white,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }


  Widget _buildDotsIndicatorExternal(Sector sector) {
    final maxDots = 10;
    final dotsCount = sector.sectorPhotos.length > maxDots ? maxDots : sector.sectorPhotos.length;
    final currentPage = _currentPages[sector.id] ?? 0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(dotsCount, (index) {
        final isActive = index == currentPage;
        return GestureDetector(
          onTap: () {
            _pageControllers[sector.id]?.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: isActive ? 16 : 12,
            height: isActive ? 16 : 12,
            decoration: BoxDecoration(
              color: isActive 
                ? const Color(0xFF8C7A6A)
                : const Color(0xFF8C7A6A).withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(isActive ? 8 : 6),
            ),
          ),
        );
      }),
    );
  }



  Widget _buildSectorBottomSheet(Sector sector) {
    return CustomBottomSheet(
      title: 'المقسم رقم ${sector.code}',
      child: Column(
        children: [
          if (sector.hasApartments || sector.hasShares || sector.hasAdditionalInfo) ...[
            if (sector.hasApartments)
              CustomButton(
                title: 'عرض العقارات المتاحة (${sector.apartmentsCount})',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchResultsPage(
                        searchType: 'apartment',
                        searchQuery: 'عقارات المقسم ${sector.code}',
                        originalSearchParams: {
                          'regionId': _selectedRegion?.id,
                          'sectorId': sector.id,
                        },
                      ),
                    ),
                  );
                },
                hasGradient: true,
                textColor: Colors.white,
              ),
            if (sector.hasApartments) const SizedBox(height: 12),
            if (sector.hasShares)
              CustomButton(
                title: 'عرض الأسهم المتاحة (${sector.sharesCount})',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchResultsPage(
                        searchType: 'share',
                        searchQuery: 'أسهم المقسم ${sector.code}',
                        originalSearchParams: {
                          'regionId': _selectedRegion?.id,
                          'sectorId': sector.id,
                        },
                      ),
                    ),
                  );
                },
                hasGradient: true,
                gradientColors: const [Color(0xFF8C7A6A), Color(0xFFA89081)],
                textColor: Colors.white,
              ),
            if (sector.hasShares) const SizedBox(height: 12),
            if (sector.hasAdditionalInfo)
              CustomButton(
                title: 'إظهار المعلومات الإضافية',
                onPressed: () {
                  Navigator.pop(context);
                  _showSectorInfoBottomSheet(sector);
                },
                hasGradient: false,
                borderColor: const Color(0xFFE0E0E0),
                textColor: const Color(0xFF2D2D2D),
              ),
          ] else ...[
            const Text(
              'لا توجد عقارات أو أسهم متاحة في هذا المقسم',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectorInfoBottomSheet(Sector sector) {
    final List<Widget> infoRows = [];
    void addInfoRow(String title, String? value) {
      if (value != null && value.isNotEmpty) {
        // If value is a number and equals 0, skip
        final numValue = num.tryParse(value.replaceAll(RegExp(r'[^0-9\.]'), ''));
        if (numValue != null && numValue == 0) return;
        infoRows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8C7A6A),
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2D2D2D),
                      fontFamily: 'Cairo',
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    addInfoRow('الوصف', sector.description);
    addInfoRow('المساحة الخارجية', sector.outerArea != null && sector.outerArea!.isNotEmpty ? '${sector.outerArea} متر مربع' : null);
    addInfoRow('المساحة السكنية', sector.residentialArea != null && sector.residentialArea!.isNotEmpty ? '${sector.residentialArea} متر مربع' : null);
    addInfoRow('المساحة التجارية', sector.commercialArea != null && sector.commercialArea!.isNotEmpty ? '${sector.commercialArea} متر مربع' : null);
    addInfoRow('مساحة البناء', sector.buildingArea != null && sector.buildingArea!.isNotEmpty ? '${sector.buildingArea} متر مربع' : null);
    addInfoRow('إجمالي مساحة الطوابق', sector.totalFloorArea != null && sector.totalFloorArea!.isNotEmpty ? '${sector.totalFloorArea} متر مربع' : null);
    addInfoRow('عدد الطوابق', sector.floorsNumber);
    addInfoRow('المقاول', sector.contractor);
    addInfoRow('المهندسون', sector.engineers);

    return CustomBottomSheet(
      title: 'معلومات إضافية للمقسم ${sector.code}',
      child: infoRows.isNotEmpty
          ? LayoutBuilder(
              builder: (context, constraints) {
                // Use max 60% of screen height, else shrink to fit
                final maxHeight = MediaQuery.of(context).size.height * 0.6;
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: maxHeight,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: infoRows,
                    ),
                  ),
                );
              },
            )
          : const Center(
              child: Text(
                'لا توجد معلومات إضافية لعرضها',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  fontFamily: 'Cairo',
                ),
                textAlign: TextAlign.center,
              ),
            ),
    );
  }


  Widget _buildSectorSkeletonCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        period: const Duration(milliseconds: 1500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 350,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 24,
              width: 120,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  height: 18,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  height: 18,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
} 