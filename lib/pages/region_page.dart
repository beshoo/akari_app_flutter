import 'package:flutter/material.dart';
import '../data/models/share_model.dart';
import '../data/repositories/share_repository.dart';
import '../widgets/share_card.dart';
import '../widgets/custom_app_bar.dart';

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

class _RegionPageState extends State<RegionPage> {
  final ShareRepository _shareRepository = ShareRepository();
  final ScrollController _scrollController = ScrollController();
  
  List<Share> shares = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMorePages = true;
  int currentPage = 1;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadShares(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.95) {
      if (!isLoadingMore && hasMorePages) {
        _loadMoreShares();
      }
    }
  }

  Future<void> _loadShares({bool refresh = false}) async {
    if (widget.regionId == null) return;

    setState(() {
      if (refresh) {
        isLoading = true;
        errorMessage = null;
        shares.clear();
        currentPage = 1;
        hasMorePages = true;
      }
    });

    try {
      final response = await _shareRepository.fetchShares(
        regionId: widget.regionId!,
        page: currentPage,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            shares = response.shares;
          } else {
            shares.addAll(response.shares);
          }
          
          hasMorePages = response.hasNextPage;
          isLoading = false;
          errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadMoreShares() async {
    if (widget.regionId == null || !hasMorePages || isLoadingMore) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      currentPage++;
      final response = await _shareRepository.fetchShares(
        regionId: widget.regionId!,
        page: currentPage,
      );

      if (mounted) {
        setState(() {
          shares.addAll(response.shares);
          hasMorePages = response.hasNextPage;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingMore = false;
          currentPage--; // Revert page increment on error
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
    
    await _loadShares(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: CustomAppBar(
        title: widget.regionName ?? 'الأسهم',
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        onHelpPressed: () {
          // TODO: Handle help press
        },
        onNotificationPressed: () {
          // TODO: Handle notification press
        },
        onSearchPressed: () {
          // TODO: Handle search press
        },
        onFavoritesPressed: () {
          // TODO: Handle favorites press
        },
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (shares.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshShares,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: shares.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == shares.length) {
            return _buildLoadingMoreIndicator();
          }

          return ShareCard(
            share: shares[index],
            scrollController: _scrollController,
            onShareUpdated: (updatedShare) {
              setState(() {
                shares[index] = updatedShare;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/connection_lost.png',
            height: 120,
            width: 120,
          ),
          const SizedBox(height: 16),
          const Text(
            'حدث خطأ في التحميل',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'خطأ غير معروف',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadShares(refresh: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF633e3d),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refreshShares,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height - 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/empty_status.png',
                  height: 120,
                  width: 120,
                ),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد أسهم متاحة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'سيتم عرض الأسهم المتاحة في هذه المنطقة',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _loadShares(refresh: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF633e3d),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('إعادة التحميل'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 