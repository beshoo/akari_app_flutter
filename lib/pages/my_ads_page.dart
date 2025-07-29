import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../stores/ads_store.dart';
import '../data/repositories/share_repository.dart';
import '../data/repositories/apartment_repository.dart';
import '../utils/navigation_helper.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/custom_spinner.dart';
import '../widgets/custom_bottom_sheet.dart';

class MyAdsPage extends StatelessWidget {
  const MyAdsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdsStore(),
      child: const _MyAdsView(),
    );
  }
}

class _MyAdsView extends StatefulWidget {
  const _MyAdsView();

  @override
  State<_MyAdsView> createState() => _MyAdsViewState();
}

class _MyAdsViewState extends State<_MyAdsView> with TickerProviderStateMixin {
  late AdsStore store;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    store = Provider.of<AdsStore>(context, listen: false);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      store.setTab(_tabController.index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      store.loadAds();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5F2),
        appBar: CustomAppBar(
          showBackButton: true,
          showFavoritesButton: true,
          showSearchButton: false,
          showHelpButton: false,
          showAddAdButton: true,

          showNotificationButton: true,
          showLogo: true,
          titleStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF633e3d),
            fontFamily: 'Cairo',
          ),
        ),
        body: SafeArea(
          bottom: true,
          child: Column(
            children: [
              Consumer<AdsStore>(
                builder: (context, store, _) => _buildTabs(store),
              ),
              Consumer<AdsStore>(
                builder: (context, store, _) => _buildFilterBar(store),
              ),
              Expanded(
                child: Consumer<AdsStore>(
                  builder: (context, store, _) => _buildAdsList(store),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: 3, // My Ads tab (إعلاناتي)
          onTap: (index) {
            // Navigation is handled by CustomBottomNavBar
          },
        ),
      ),
    );
  }

  Widget _buildTabs(AdsStore store) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF633e3d),
        labelColor: const Color(0xFF633e3d),
        unselectedLabelColor: const Color(0xFFBDBDBD),
        labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
        tabs: const [
          Tab(text: 'إعلانات الأسهم'),
          Tab(text: 'إعلانات العقارات'),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AdsStore store) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.filter_list,
            color: Color(0xFF633e3d),
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'تصفية:',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF633e3d),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(store, 'الكل', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip(store, 'نية شراء', 'buy'),
                  const SizedBox(width: 8),
                  _buildFilterChip(store, 'نية بيع', 'sell'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(AdsStore store, String label, String value) {
    final isSelected = store.currentFilter == value;
    return GestureDetector(
      onTap: () => store.setFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF633e3d) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF633e3d) : const Color(0xFFBDBDBD),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF633e3d),
          ),
        ),
      ),
    );
  }

  Widget _buildAdsList(AdsStore store) {
    if (store.isLoading) {
      return const Center(child: CustomSpinner(size: 50.0));
    }
    
    final ads = store.currentAds;
    if (ads.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => store.loadAds(force: true),
        color: const Color(0xFF633e3d),
        backgroundColor: const Color(0xFFF7F5F2),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: _buildEmptyState(store.currentTab),
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () => store.loadAds(force: true),
      color: const Color(0xFF633e3d),
      backgroundColor: const Color(0xFFF7F5F2),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            if (store.hasMoreData && !store.isLoadingMore) {
              store.loadMoreAds();
            }
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: ads.length + (store.hasMoreData ? 1 : 0),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          itemBuilder: (context, index) {
            if (index == ads.length) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: store.isLoadingMore 
                    ? const CustomSpinner(size: 30.0)
                    : const SizedBox.shrink(),
                ),
              );
            }
            final ad = ads[index];
            return _AdListItem(
              ad: ad,
              type: store.currentTab == 0 ? 'share' : 'apartment',
              onDelete: () => store.confirmDelete(context, ad, store.currentTab == 0 ? 'share' : 'apartment'),
              onTap: () => NavigationHelper.navigateToDetails(context, ad['id'], store.currentTab == 0 ? 'share' : 'apartment'),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(int tab) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/no_data.png', width: 120, height: 120),
            const SizedBox(height: 24),
            const Text(
              'لا توجد إعلانات حتى الآن',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF633e3d)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildCreateAdButton(tab),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateAdButton(int tab) {
    final buttonText = tab == 0 ? 'إضافة إعلان أسهم تنظيمية' : 'إضافة إعلان عقار';
    final buttonIcon = tab == 0 ? Icons.trending_up : Icons.home_outlined;
    
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF633E3D),
            Color(0xFF774B46),
            Color(0xFF8D5E52),
            Color(0xFFA47764),
            Color(0xFFBDA28C),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF633E3D).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (tab == 0) {
              NavigationHelper.navigateToCreateShare(context);
            } else {
              NavigationHelper.navigateToCreateApartment(context);
            }
          },
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  buttonIcon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  buttonText,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdListItem extends StatelessWidget {
  final Map<String, dynamic> ad;
  final String type;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _AdListItem({
    required this.ad,
    required this.type,
    required this.onDelete,
    required this.onTap,
  });

  // Reaction data
  final Map<String, String> _reactionEmojis = const {
    'like': '👍🏼',
    'love': '❤️',
    'wow': '😮',
    'sad': '😢',
    'angry': '😠',
  };


  @override
  Widget build(BuildContext context) {
    final sector = ad['sector'];
    final region = ad['region'];
    final coverImg = sector?['cover']?['img'] ?? '';
    final imageUrl = coverImg.isNotEmpty ? coverImg : 'assets/images/no_photo.jpg';
    final transactionType = ad['transaction_type'] == 'sell' ? 'نية بيع' : 'نية شراء';
    final sectorName = sector?['sector_name']?['name'] ?? '';
    final sectorCode = sector?['sector_name']?['code'] ?? '';
    final price = ad['price']?.toString() ?? '';
    final regionName = region?['name'] ?? '';
    final views = ad['views']?.toString() ?? '0';
    final since = ad['since'] ?? '';
    final approve = ad['approve'] == 1;
    final isClosed = ad['closed'] == 1;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color.fromARGB(255, 231, 226, 219),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                            Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F0F0),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF633e3d)),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => Image.asset('assets/images/no_photo.jpg', width: 72, height: 72, fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 72,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: approve ? Colors.green : Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  approve ? 'مُعتمد' : 'قيد المراجعة',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$regionName - $transactionType',
                                  style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$sectorName - $sectorCode', 
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, color: Color.fromARGB(255, 51, 51, 51)),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'السعر: $price', 
                                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 15, color: Color(0xFF633e3d)),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // iOS-style three-dot menu in top-left corner
                  Positioned(
                    top: -15,
                    left: -15,
                    child: _buildThreeDotMenu(context, isClosed),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('$views مشاهدة', style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(since, style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey[600])),
                  // Reaction summary at the end
                  if (_getTotalReactionCount() > 0) ...[
                    const Spacer(),
                    _buildReactionSummary(context),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getTotalReactionCount() {
    final reactionCounts = ad['reaction_counts'] as Map<String, dynamic>?;
    if (reactionCounts == null) {
      // Add mock reaction data for testing
      return _getMockReactionCount();
    }
    return reactionCounts['total_count'] ?? 0;
  }

  int _getMockReactionCount() {
    // Generate a random total count between 0 and 15 for testing
    final random = DateTime.now().millisecond % 16;
    return random;
  }

  List<String> _getVisibleReactions() {
    final reactionCounts = ad['reaction_counts'] as Map<String, dynamic>?;
    if (reactionCounts == null) {
      // Return mock reactions for testing
      return _getMockVisibleReactions();
    }
    
    final counts = <String, int>{
      'like': reactionCounts['like_count'] ?? 0,
      'love': reactionCounts['love_count'] ?? 0,
      'wow': reactionCounts['wow_count'] ?? 0,
      'sad': reactionCounts['sad_count'] ?? 0,
      'angry': reactionCounts['angry_count'] ?? 0,
    };
    
    // Filter reactions with count > 0 and sort by count (descending)
    final sortedReactions = counts.entries
        .where((entry) => entry.value > 0)
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedReactions.map((entry) => entry.key).toList();
  }

  List<String> _getMockVisibleReactions() {
    final totalCount = _getMockReactionCount();
    if (totalCount == 0) return [];
    
    // Generate some mock reactions based on the total count
    final reactions = <String>[];
    
    if (totalCount > 0) reactions.add('like');
    if (totalCount > 3) reactions.add('love');
    if (totalCount > 6) reactions.add('wow');
    if (totalCount > 9) reactions.add('sad');
    if (totalCount > 12) reactions.add('angry');
    
    return reactions;
  }

  Widget _buildReactionSummary(BuildContext context) {
    final reactions = _getVisibleReactions();
    return GestureDetector(
      onTap: () => _showReactionModal(context),
      child: Container(
        padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2, right: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Overlapping reaction emojis
            if (reactions.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < reactions.length; i++)
                    Transform.translate(
                      offset: Offset(3.0 * i, 0), // Less overlap for smaller size
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 1,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(1),
                        child: Text(
                          _reactionEmojis[reactions[i]]!,
                          style: const TextStyle(fontSize: 14), // Smaller emoji size
                        ),
                      ),
                    ),
                ],
              ),
            if (reactions.isNotEmpty)
              const SizedBox(width: 2), // Smaller spacing
            // Small count
            Text(
              '${_getTotalReactionCount()}',
              style: const TextStyle(
                fontSize: 11, // Smaller font size
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReactionModal(BuildContext context) {
    showMaterialModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomBottomSheet(
        title: 'التفاعلات',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _getVisibleReactions().map((reaction) {
            final count = _getReactionCount(reaction);
            return Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _reactionEmojis[reaction]!,
                    style: const TextStyle(fontSize: 24),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  int _getReactionCount(String reaction) {
    final reactionCounts = ad['reaction_counts'] as Map<String, dynamic>?;
    if (reactionCounts == null) {
      // Return mock reaction count for testing
      return _getMockReactionCountForType(reaction);
    }
    
    switch (reaction) {
      case 'like':
        return reactionCounts['like_count'] ?? 0;
      case 'love':
        return reactionCounts['love_count'] ?? 0;
      case 'wow':
        return reactionCounts['wow_count'] ?? 0;
      case 'sad':
        return reactionCounts['sad_count'] ?? 0;
      case 'angry':
        return reactionCounts['angry_count'] ?? 0;
      default:
        return 0;
    }
  }

  int _getMockReactionCountForType(String reaction) {
    final totalCount = _getMockReactionCount();
    if (totalCount == 0) return 0;
    
    // Distribute the total count across different reaction types
    switch (reaction) {
      case 'like':
        return (totalCount * 0.4).round();
      case 'love':
        return (totalCount * 0.3).round();
      case 'wow':
        return (totalCount * 0.2).round();
      case 'sad':
        return (totalCount * 0.08).round();
      case 'angry':
        return (totalCount * 0.02).round();
      default:
        return 0;
    }
  }

  Widget _buildThreeDotMenu(BuildContext context, bool isClosed) {
    return PopupMenuButton<String>(
      icon: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 252, 246, 246).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.more_vert,
          size: 20,
          color: Color(0xFF633e3d),
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 8,
      color: const Color.fromARGB(255, 250, 246, 246),
      offset: const Offset(10, 45),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            if (!isClosed) _navigateToEdit(context);
            break;
          case 'delete':
            if (!isClosed) onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        if (!isClosed) ...[
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Image.asset(
                  'assets/images/icons/edit.png',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'تعديل',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF633e3d),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Image.asset(
                  'assets/images/icons/delete_icon.png',
                  width: 20,
                  height: 20,
                  color: Colors.red,
                ),
                const SizedBox(width: 12),
                const Text(
                  'حذف',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          PopupMenuItem<String>(
            value: 'sold',
            enabled: false,
            child: Row(
              children: [
                Icon(
                  Icons.lock,
                  size: 20,
                  color: const Color(0xFFBDBDBD),
                ),
                const SizedBox(width: 12),
                const Text(
                  'مُباع',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFBDBDBD),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _navigateToEdit(BuildContext context) async {
    final adId = ad['id'];
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CustomSpinner(size: 50.0),
      ),
    );
    
    try {
      if (type == 'share') {
        final shareRepository = ShareRepository();
        final share = await shareRepository.fetchShareById(adId);
        Navigator.pop(context); // Close loading dialog
        if (share != null) {
          NavigationHelper.navigateToUpdateShare(context, share);
        } else {
          NavigationHelper.navigateToCreateShare(context);
        }
      } else {
        final apartmentRepository = ApartmentRepository();
        final apartment = await apartmentRepository.fetchApartmentById(adId);
        Navigator.pop(context); // Close loading dialog
        if (apartment != null) {
          NavigationHelper.navigateToUpdateApartment(context, apartment);
        } else {
          NavigationHelper.navigateToCreateApartment(context);
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      // Fallback to create forms
      if (type == 'share') {
        NavigationHelper.navigateToCreateShare(context);
      } else {
        NavigationHelper.navigateToCreateApartment(context);
      }
    }
  }
} 