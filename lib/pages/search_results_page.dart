import 'package:flutter/material.dart';
import '../data/models/apartment_model.dart';
import '../data/models/share_model.dart';
import '../data/repositories/share_repository.dart';
import '../data/repositories/apartment_repository.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_spinner.dart';
import '../widgets/post_card.dart';
import '../widgets/post_card_data.dart';
import '../stores/auth_store.dart';
import '../utils/logger.dart';
import 'package:provider/provider.dart';

class SearchResultsPage extends StatefulWidget {
  final String searchType; // 'apartment' or 'share'
  final Map<String, dynamic>? searchData;
  final String searchQuery; // For display purposes
  final Map<String, dynamic>? originalSearchParams; // Store original search parameters

  const SearchResultsPage({
    super.key,
    required this.searchType,
    this.searchData,
    required this.searchQuery,
    this.originalSearchParams,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  List<PostCardData> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalResults = 0;
  final ScrollController _scrollController = ScrollController();
  
  // Add repositories for pagination
  final ShareRepository _shareRepository = ShareRepository();
  final ApartmentRepository _apartmentRepository = ApartmentRepository();

  @override
  void initState() {
    super.initState();
    if (widget.searchData != null) {
      _parseSearchResults();
    } else {
      _performSearch();
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Trigger pagination when user is about 3 cards away from the end (85% of scroll)
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.85) {
      _loadNextPage();
    }
  }

  void _parseSearchResults() {
    if (widget.searchData == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = widget.searchData!['data'] as List<dynamic>? ?? [];
      _currentPage = widget.searchData!['current_page'] ?? 1;
      _totalPages = widget.searchData!['last_page'] ?? 1;
      _totalResults = widget.searchData!['total'] ?? 0;

      Logger.log('📊 Parsing ${widget.searchType} search results: ${data.length} items');
      Logger.log('📄 Page $_currentPage of $_totalPages (Total: $_totalResults)');

      final authStore = Provider.of<AuthStore>(context, listen: false);
      final showOwner = authStore.userPrivilege == 'admin' || authStore.userPrivilege == 'owner';

      if (widget.searchType == 'apartment') {
        _searchResults = data.map((item) {
          final apartment = Apartment.fromJson(item as Map<String, dynamic>);
          return ApartmentPostAdapter(apartment, showOwner: showOwner);
        }).toList();
      } else if (widget.searchType == 'share') {
        _searchResults = data.map((item) {
          final share = Share.fromJson(item as Map<String, dynamic>);
          return SharePostAdapter(share, showOwner: showOwner);
        }).toList();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      Logger.log('❌ Error parsing search results: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطأ في تحليل نتائج البحث';
      });
    }
  }

  void _performSearch() async {
    if (widget.originalSearchParams == null) {
      setState(() {
        _errorMessage = 'لا توجد معاملات بحث متاحة';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authStore = Provider.of<AuthStore>(context, listen: false);
      final showOwner = authStore.userPrivilege == 'admin' || authStore.userPrivilege == 'owner';

      if (widget.searchType == 'apartment') {
        final params = widget.originalSearchParams!;
        final response = await _apartmentRepository.searchApartments(
          apartmentTypeId: params['apartmentTypeId'],
          regionId: params['regionId'],
          sectorId: params['sectorId'],
          directionId: params['directionId'],
          paymentMethodId: params['paymentMethodId'],
          apartmentStatusId: params['apartmentStatusId'],
          area: params['area'],
          floor: params['floor'],
          roomsCount: params['roomsCount'],
          salonsCount: params['salonsCount'],
          balconyCount: params['balconyCount'],
          isTaras: params['isTaras'],
          equity: params['equity'],
          price: params['price'],
          transactionType: params['transactionType'],
          priceOperator: params['priceOperator'],
          equityOperator: params['equityOperator'],
          ownerName: params['ownerName'],
        );

        _currentPage = response.currentPage;
        _totalPages = response.lastPage;
        _totalResults = response.total;

        _searchResults = response.apartments.map((apartment) {
          return ApartmentPostAdapter(apartment, showOwner: showOwner);
        }).toList();
      } else if (widget.searchType == 'share') {
        final params = widget.originalSearchParams!;
        final response = await _shareRepository.searchShares(
          id: params['id'],
          regionId: params['regionId'],
          sectorId: params['sectorId'],
          quantity: params['quantity'],
          quantityOperator: params['quantityOperator'],
          transactionType: params['transactionType'],
          price: params['price'],
          priceOperator: params['priceOperator'],
          ownerName: params['ownerName'],
        );

        _currentPage = response.currentPage;
        _totalPages = response.lastPage;
        _totalResults = response.total;

        _searchResults = response.shares.map((share) {
          return SharePostAdapter(share, showOwner: showOwner);
        }).toList();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      Logger.log('❌ Error performing search: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ أثناء البحث: ${e.toString()}';
      });
    }
  }

  void _loadNextPage() async {
    if (_currentPage < _totalPages && !_isLoading && widget.originalSearchParams != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final nextPage = _currentPage + 1;
        Logger.log('📄 Loading page $nextPage');

        if (widget.searchType == 'apartment') {
          await _loadNextApartmentPage(nextPage);
        } else if (widget.searchType == 'share') {
          await _loadNextSharePage(nextPage);
        }
      } catch (e) {
        Logger.log('❌ Error loading next page: $e');
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل في تحميل المزيد من النتائج'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadNextSharePage(int page) async {
    final params = widget.originalSearchParams!;
    
    final response = await _shareRepository.searchShares(
      id: params['id'],
      regionId: params['regionId'],
      sectorId: params['sectorId'],
      quantity: params['quantity'],
      quantityOperator: params['quantityOperator'],
      transactionType: params['transactionType'],
      price: params['price'],
      priceOperator: params['priceOperator'],
      ownerName: params['ownerName'],
      page: page,
    );

    if (mounted) {
      final authStore = Provider.of<AuthStore>(context, listen: false);
      final showOwner = authStore.userPrivilege == 'admin' || authStore.userPrivilege == 'owner';

      final newResults = response.shares.map((share) {
        return SharePostAdapter(share, showOwner: showOwner);
      }).toList();

      setState(() {
        _searchResults.addAll(newResults);
        _currentPage = response.currentPage;
        _totalPages = response.lastPage;
        _totalResults = response.total;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNextApartmentPage(int page) async {
    final params = widget.originalSearchParams!;
    
    final response = await _apartmentRepository.searchApartments(
      regionId: params['regionId'],
      sectorId: params['sectorId'],
      directionId: params['directionId'],
      apartmentTypeId: params['apartmentTypeId'],
      paymentMethodId: params['paymentMethodId'],
      apartmentStatusId: params['apartmentStatusId'],
      area: params['area'],
      floor: params['floor'],
      roomsCount: params['roomsCount'],
      salonsCount: params['salonsCount'],
      balconyCount: params['balconyCount'],
      isTaras: params['isTaras'],
      equity: params['equity'],
      equityOperator: params['equityOperator'],
      price: params['price'],
      priceOperator: params['priceOperator'],
      ownerName: params['ownerName'],
      page: page,
    );

    if (mounted) {
      final authStore = Provider.of<AuthStore>(context, listen: false);
      final showOwner = authStore.userPrivilege == 'admin' || authStore.userPrivilege == 'owner';

      final newResults = response.apartments.map((apartment) {
        return ApartmentPostAdapter(apartment, showOwner: showOwner);
      }).toList();

      setState(() {
        _searchResults.addAll(newResults);
        _currentPage = response.currentPage;
        _totalPages = response.lastPage;
        _totalResults = response.total;
        _isLoading = false;
      });
    }
  }

  void _onPostUpdated(PostCardData updatedPost) {
    setState(() {
      final index = _searchResults.indexWhere((post) => post.id == updatedPost.id);
      if (index != -1) {
        _searchResults[index] = updatedPost;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: CustomAppBar(
        title: _getPageTitle(),
        showBackButton: true,
        showLogo: false,
        titleStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 0, 0, 0),
        ),
      ),
      body: _buildBody(),
    );
  }

  String _getPageTitle() {
    if (widget.searchType == 'apartment') {
      return 'البحث عن العقارات';
    } else {
      return 'البحث عن الأسهم';
    }
  }

  Widget _buildBody() {
    if (_isLoading && _searchResults.isEmpty) {
      return const Center(
        child: CustomSpinner(size: 50.0),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyResults();
    }

    return Column(
      children: [
        _buildResultsHeader(),
        Expanded(
          child: _buildResultsList(),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/connection_lost.png',
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF633E3D),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _parseSearchResults,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF633E3D),
              foregroundColor: Colors.white,
            ),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/no_data.png',
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 24),
          const Text(
            'لا توجد نتائج',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF633E3D),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'لم يتم العثور على نتائج مطابقة لبحثك.\nجرب تعديل معايير البحث.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F5F2),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'النتائج الموجودة',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF633E3D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_totalResults ${widget.searchType == 'apartment' ? 'عقار' : 'سهم'} موجود',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF633E3D).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'صفحة $_currentPage من $_totalPages',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF633E3D),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return RefreshIndicator(
      onRefresh: () async {
        _parseSearchResults();
      },
      color: const Color(0xFF633E3D),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _searchResults.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _searchResults.length) {
            // Loading indicator for pagination
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CustomSpinner(size: 40.0),
              ),
            );
          }

          return PostCard(
            postData: _searchResults[index],
            onPostUpdated: _onPostUpdated,
            scrollController: _scrollController,
          );
        },
      ),
    );
  }
} 