import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:shimmer/shimmer.dart';
import '../data/models/apartment_model.dart';
import '../data/models/share_model.dart';
import '../data/repositories/apartment_repository.dart';
import '../data/repositories/share_repository.dart';
import '../stores/auth_store.dart';
import '../stores/reaction_store.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_spinner.dart';
import '../utils/toast_helper.dart';
import 'apartment_form_page.dart';
import 'share_form_page.dart';
import '../widgets/custom_bottom_sheet.dart';
import '../widgets/custom_dialog.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import '../utils/logger.dart';
import 'contact_us_page.dart';

class PropertyDetailsPage extends StatefulWidget {
  final int id;
  final String itemType; // "apartment" or "share"

  const PropertyDetailsPage({
    super.key,
    required this.id,
    required this.itemType,
  });

  @override
  State<PropertyDetailsPage> createState() => _PropertyDetailsPageState();
}

class _PropertyDetailsPageState extends State<PropertyDetailsPage> with TickerProviderStateMixin {
  final ApartmentRepository _apartmentRepository = ApartmentRepository();
  final ShareRepository _shareRepository = ShareRepository();
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();

  // State management
  dynamic _itemData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showReactions = false;
  int _currentPhotoIndex = 0;
  late AnimationController _reactionAnimationController;
  late Animation<double> _reactionScaleAnimation;
  
  // Reaction data
  final Map<String, String> _reactionEmojis = {
    'like': '👍🏼',
    'love': '❤️',
    'wow': '😮',
    'sad': '😢',
    'angry': '😠',
  };

  final Map<String, String> _reactionNames = {
    'like': 'إعجاب',
    'love': 'أحببته',
    'wow': 'أدهشني',
    'sad': 'أحزنني',
    'angry': 'أغضبني',
  };

  @override
  void initState() {
    super.initState();
    _loadItemDetails();
    _reactionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _reactionScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _reactionAnimationController,
      curve: Curves.easeInOut,
    ));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _reactionAnimationController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_showReactions) {
      setState(() {
        _showReactions = false;
      });
    }
  }

  Future<void> _loadItemDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Log auth information on API call
      final authStore = Provider.of<AuthStore>(context, listen: false);
      Logger.log('🔐 Auth Info - User ID: ${authStore.userId ?? 'null'}');
      Logger.log('🔐 Auth Info - User Privilege: ${authStore.userPrivilege ?? 'null'}');
      Logger.log('🔐 Auth Info - User Name: ${authStore.userName ?? 'null'}');
      Logger.log('🔐 Auth Info - Is Authenticated: ${authStore.isAuthenticated}');

      if (widget.itemType == "apartment") {
        final response = await _apartmentRepository.fetchApartmentById(widget.id);
        _itemData = response;
        Logger.log('🏠 Apartment data loaded - Item User ID: ${_itemData.userId}');
      } else if (widget.itemType == "share") {
        final response = await _shareRepository.fetchShareById(widget.id);
        _itemData = response;
        Logger.log('📈 Share data loaded - Item User ID: ${_itemData.userId}');
      } else {
        throw Exception('نوع العنصر غير صحيح');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'حدث خطأ في تحميل التفاصيل: ${e.toString()}';
      });
    }
  }

  String _getTransactionText() {
    if (_itemData == null) return '';
    
    final baseText = widget.itemType == "apartment" ? "عقار" : "اسهم تنظيمية";
    final transactionType = _itemData.transactionType == 'sell' ? 'بيع' : 'شراء';
    final sectorCode = _itemData.sector.code?.viewCode ?? _itemData.sector.code?.code ?? '';
    final regionName = _itemData.region.name;
    
    if (widget.itemType == "apartment") {
      final equity = _itemData.equity;
      final price = '${_formatNumber(_itemData.priceKey.toString())} ل.س';
      final apartmentTypeName = _itemData.apartmentType?.name ?? '';
      return "نرغب ب$transactionType $baseText $apartmentTypeName في $sectorCode بكمية $equity حصة سهمية بسعر $price في منطقة $regionName";
    } else {
      final quantity = _itemData.quantity;
      final price = '${_formatNumber(_itemData.priceKey.toString())} ل.س';
      return "نرغب ب$transactionType $baseText في $sectorCode بكمية $quantity سهم بسعر $price بالسهم في منطقة $regionName";
    }
  }

  Widget _buildTransactionRichText() {
    if (_itemData == null) return const SizedBox.shrink();
    
    final baseText = widget.itemType == "apartment" ? "عقار" : "اسهم تنظيمية";
    final transactionType = _itemData.transactionType == 'sell' ? 'بيع' : 'شراء';
    final sectorCode = _itemData.sector.code?.viewCode ?? _itemData.sector.code?.code ?? '';
    final regionName = _itemData.region.name;
    
    const normalStyle = TextStyle(
      fontSize: 16,
      fontFamily: 'Cairo',
      color: Color(0xFF555555),
      height: 1.6,
    );
    
    const boldStyle = TextStyle(
      fontSize: 16,
      fontFamily: 'Cairo',
      color: Color(0xFF555555),
      height: 1.6,
      fontWeight: FontWeight.bold,
    );
    
    if (widget.itemType == "apartment") {
      final equity = _itemData.equity;
      final price = '${_formatNumber(_itemData.priceKey.toString())} ل.س';
      final apartmentTypeName = _itemData.apartmentType?.name ?? '';
      
      return RichText(
        textAlign: TextAlign.right,
        text: TextSpan(
          style: normalStyle,
          children: [
            TextSpan(text: "نرغب ب$transactionType $baseText "),
            TextSpan(text: apartmentTypeName, style: boldStyle),
            TextSpan(text: " في $sectorCode بكمية $equity حصة سهمية بسعر "),
            TextSpan(text: price, style: boldStyle),
            TextSpan(text: " في منطقة $regionName"),
          ],
        ),
      );
    } else {
      final quantity = _itemData.quantity;
      final price = '${_formatNumber(_itemData.priceKey.toString())} ل.س';
      
      return RichText(
        textAlign: TextAlign.right,
        text: TextSpan(
          style: normalStyle,
          children: [
            TextSpan(text: "نرغب ب$transactionType $baseText في $sectorCode بكمية $quantity سهم بسعر "),
            TextSpan(text: price, style: boldStyle),
            TextSpan(text: " بالسهم في منطقة $regionName"),
          ],
        ),
      );
    }
  }

  List<String> _getPhotos() {
    if (_itemData == null) return ['assets/images/no_photo.jpg'];
    
    // Get photos from sector if available
    if (_itemData.sector != null && 
        _itemData.sector.photos != null && 
        _itemData.sector.photos.isNotEmpty) {
      return _itemData.sector.photos
          .map<String>((photo) => photo['img'] as String)
          .toList();
    }
    
    // Get photos from item if available (for items that have direct media)
    if (_itemData.media != null && _itemData.media.isNotEmpty) {
      return _itemData.media
          .map<String>((media) => media['img'] as String)
          .toList();
    }
    
    // Fallback to default image
    return ['assets/images/no_photo.jpg'];
  }

  Widget _buildFixedHeader() {
    if (_itemData == null) return const SizedBox.shrink();
    
    final sectorCode = _itemData.sector.code;
    final region = _itemData.region;
    final postTypeDisplay = widget.itemType == "apartment" ? "عقارات" : "اسهم تنظيمية";
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: const BoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${sectorCode.name} - ${sectorCode.viewCode}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 8),
          Text(
            '${region.name} - $postTypeDisplay',
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Cairo',
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.right,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Cairo',
                color: Color(0xFF888888),
              ),
              children: [
                const TextSpan(text: 'الرقم المرجعي : '),
                TextSpan(
                  text: '#${_itemData.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildImageSlider() {
    final photos = _getPhotos();
    
    return Container(
      height: 300,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentPhotoIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showFullScreenPhotoViewer(index),
                child: Container(
                  width: double.infinity,
                  child: photos[index].startsWith('assets/')
                      ? Image.asset(
                          photos[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/no_photo.jpg',
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : CachedNetworkImage(
                          imageUrl: photos[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Stack(
                            children: [
                              Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  width: double.infinity,
                                  height: 300,
                                  color: Colors.grey[300],
                                ),
                              ),
                              const Center(
                                child: CustomSpinner(size: 40),
                              ),
                            ],
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/images/no_photo.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              );
            },
          ),
          // Status badge
          if (_itemData?.approve == 0)
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFe3a001), Color(0xFF7a460d)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'قيد المراجعة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClickableDots() {
    final photos = _getPhotos();
    if (photos.length <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: photos.asMap().entries.map((entry) {
          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                entry.key,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            child: Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPhotoIndex == entry.key
                    ? const Color(0xFF8B6F47)
                    : const Color(0xFF8B6F47).withOpacity(0.3),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_itemData == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Row(
        children: [
          // Reaction button (right side in RTL)
          Expanded(
            child: GestureDetector(
              onTap: () => _handleReactionButtonTap(),
              onLongPress: _handleReactionButtonLongPress,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _getCurrentReactionIcon(),
                    const SizedBox(width: 8),
                    Text(
                      _itemData.currentUserReaction != null
                          ? _reactionNames[_itemData.currentUserReaction] ?? 'إعجاب'
                          : 'إعجاب',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Cairo',
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Share button (middle in RTL)
          Expanded(
            child: GestureDetector(
              onTap: _shareContent,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.shareNodes,
                      color: const Color(0xFF999999),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'شارك',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Cairo',
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Favorite button (left side in RTL)
          Expanded(
            child: GestureDetector(
              onTap: _handleFavoriteToggle,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      _itemData.isFavorited 
                          ? FontAwesomeIcons.solidStar 
                          : FontAwesomeIcons.star,
                      color: _itemData.isFavorited 
                          ? Colors.amber 
                          : const Color(0xFF999999),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'مفضلة',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Cairo',
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCurrentReactionIcon({double size = 20}) {
    if (_itemData.currentUserReaction != null) {
      return Text(
        _reactionEmojis[_itemData.currentUserReaction]!,
        style: TextStyle(fontSize: size),
      );
    } else {
      return FaIcon(
        FontAwesomeIcons.thumbsUp, // This is the outlined version
        size: size,
        color: const Color(0xFF333333),
      );
    }
  }

  Widget _buildReactionSummary() {
    if (_itemData.reactionCounts.totalCount <= 0) {
      return const SizedBox.shrink();
    }

    final reactions = _getVisibleReactions();
    return GestureDetector(
      onTap: () => _showReactionModal(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (reactions.isNotEmpty)
              Row(
                children: [
                  for (int i = 0; i < reactions.length; i++)
                    Transform.translate(
                      offset: Offset(5.0 * i, 0),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: Text(
                          _reactionEmojis[reactions[i]]!,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                ],
              ),
            if (reactions.isNotEmpty) const SizedBox(width: 8),
            Text(
              '${_itemData.reactionCounts.totalCount}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingReactionPanel() {
    Logger.log('🎨 Building floating reaction panel, _showReactions: $_showReactions');
    return Positioned(
      bottom: 450, // Position above the action buttons (50 height + 24 padding + some margin)
      right: 20, // Position above the reaction button (right side in RTL)
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _reactionEmojis.entries.map((entry) {
            final isSelected = _itemData.currentUserReaction == entry.key;
            return GestureDetector(
              onTap: () {
                _handleReactionSelected(entry.key);
                Logger.log('🎯 Floating panel: ${entry.key} reaction tapped');
                // Hide the reaction panel after selection
                setState(() {
                  _showReactions = false;
                });
              },
              child: AnimatedBuilder(
                animation: _reactionScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isSelected ? _reactionScaleAnimation.value : 1.0,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1877F2).withOpacity(0.1)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: isSelected ? 28 : 24,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMainDetailsCard() {
    if (_itemData == null) return const SizedBox.shrink();
    
    final title = widget.itemType == "apartment" ? "تفاصيل العقار" : "تفاصيل السهم";
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E5E5)), // Lighter border color
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end, // Changed to end for RTL alignment
        children: [
          Container(
            width: double.infinity,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: Color(0xFF2D2D2D),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: _buildTransactionRichText(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridBox({
    required String iconPath,
    required String title,
    required String value,
    TextAlign? textAlign, // Add optional alignment parameter
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E5E5)), // Lighter border color
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end, // Changed to end for RTL alignment
        children: [
          // Icon area - aligned to the right
          Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 0),
            height: 60, // Fixed height for icon area
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF8B6F47).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/icons/$iconPath',
                  width: 30,
                  height: 30,
                  color: const Color(0xFF8B6F47),
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.info,
                      size: 30,
                      color: Color(0xFF8B6F47),
                    );
                  },
                ),
              ),
            ),
          ),
          // Text area - flexible height that adapts to content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end, // RTL alignment
              mainAxisAlignment: MainAxisAlignment.start, // Keep title and value together at top
              children: [
                // Title area - auto height based on content
                Container(
                  width: double.infinity,
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold, // Made bold
                        fontFamily: 'Cairo',
                        color: Color(0xFF666666),
                        height: 1.3, // Line height for better spacing
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Value area - auto height based on content
                Container(
                  width: double.infinity,
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal, // Removed bold
                        fontFamily: 'Cairo',
                        color: Color(0xFF1A1A1A),
                        height: 1.2, // Line height for better spacing
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEqualHeightGridRow(List<Widget> children) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildApartmentGridRows() {
    if (_itemData == null) return const SizedBox.shrink();
    
    final apartment = _itemData as Apartment;
    final apartmentTypeName = apartment.apartmentType.name.isNotEmpty 
        ? apartment.apartmentType.name 
        : 'غير محدد';
    
    // Debug logging
    Logger.log('🏠 Apartment Type Debug:');
    Logger.log('   - apartmentType object: ${apartment.apartmentType}');
    Logger.log('   - apartmentType.name: "${apartment.apartmentType.name}"');
    Logger.log('   - apartmentTypeName final: "$apartmentTypeName"');
    
    // Helper function to check if value should be shown
    bool shouldShowValue(dynamic value) {
      if (value == null) return false;
      if (value is int && value == 0) return false;
      if (value is double && value == 0.0) return false;
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return false;
        // Check if string represents zero
        final parsed = double.tryParse(trimmed);
        if (parsed != null && parsed == 0.0) return false;
      }
      return true;
    }
    
    // Collect all visible main detail boxes
    List<Widget> mainDetailBoxes = [];
    
    if (shouldShowValue(apartmentTypeName)) {
      mainDetailBoxes.add(_buildGridBox(
        iconPath: 'building_type.png',
        title: 'نوع العقار',
        value: apartmentTypeName,
        textAlign: TextAlign.right,
      ));
    }
    
    if (shouldShowValue(apartment.priceKey)) {
      mainDetailBoxes.add(_buildGridBox(
        iconPath: 'price.png',
        title: 'سعر العقار',
        value: '${_formatNumber(apartment.priceKey.toString())} ل.س',
        textAlign: TextAlign.right,
      ));
    }
    
    if (shouldShowValue(apartment.equity)) {
      mainDetailBoxes.add(_buildGridBox(
        iconPath: 'quantity.png',
        title: 'اسهم العقار',
        value: apartment.equity,
        textAlign: TextAlign.right,
      ));
    }
    
    if (shouldShowValue(apartment.region.name)) {
      mainDetailBoxes.add(_buildGridBox(
        iconPath: 'location.png',
        title: 'المنطقة',
        value: apartment.region.name,
        textAlign: TextAlign.right,
      ));
    }
    
    if (shouldShowValue(apartment.sector.code.name)) {
      mainDetailBoxes.add(_buildGridBox(
        iconPath: 'sector.png',
        title: 'القطاع',
        value: apartment.sector.code.name,
        textAlign: TextAlign.right,
      ));
    }
    
    if (shouldShowValue(apartment.sector.code.code)) {
      mainDetailBoxes.add(_buildGridBox(
        iconPath: 'section_number.png',
        title: 'رقم المقسم',
        value: apartment.sector.code.code,
        textAlign: TextAlign.right,
      ));
    }
    
    if (shouldShowValue(apartment.area)) {
      mainDetailBoxes.add(_buildGridBox(
        iconPath: 'area.png',
        title: 'المساحة',
        value: '${apartment.area} م²',
        textAlign: TextAlign.right,
      ));
    }
    
    if (shouldShowValue(apartment.direction.name)) {
      mainDetailBoxes.add(_buildGridBox(
        iconPath: 'direction.png',
        title: 'اتجاه العقار',
        value: apartment.direction.name,
        textAlign: TextAlign.right,
      ));
    }
    
    if (shouldShowValue(apartment.floor)) {
      mainDetailBoxes.add(_buildGridBox(
        iconPath: 'floor.png',
        title: 'الطابق',
        value: apartment.floor.toString(),
        textAlign: TextAlign.right,
      ));
    }
    
    if (apartment.paymentMethod != null && shouldShowValue(apartment.paymentMethod!.name)) {
      mainDetailBoxes.add(_buildGridBox(
        iconPath: 'mobile.png',
        title: 'طريقة الدفع',
        value: apartment.paymentMethod!.name,
        textAlign: TextAlign.right,
      ));
    }
    
    return Column(
      children: [
        // Build rows of 3 boxes each
        ...List.generate(
          (mainDetailBoxes.length / 3).ceil(),
          (rowIndex) {
            final startIndex = rowIndex * 3;
            final endIndex = (startIndex + 3).clamp(0, mainDetailBoxes.length);
            final rowBoxes = mainDetailBoxes.sublist(startIndex, endIndex);
            
            // Pad with empty space if less than 3 boxes
            while (rowBoxes.length < 3) {
              rowBoxes.add(const SizedBox());
            }
            
            return Column(
              children: [
                if (rowIndex > 0) const SizedBox(height: 8),
                _buildEqualHeightGridRow([
                  Expanded(child: rowBoxes[0]),
                  const SizedBox(width: 8),
                  Expanded(child: rowBoxes[1]),
                  const SizedBox(width: 8),
                  Expanded(child: rowBoxes[2]),
                ]),
              ],
            );
          },
        ),
        
        // Conditional additional details
        if (_shouldShowAdditionalDetails(apartment)) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E5E5)), // Lighter border color
              borderRadius: BorderRadius.circular(8),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: const Text(
                'تفاصيل إضافية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: Color(0xFF2D2D2D),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Additional details rows
          if (shouldShowValue(apartment.roomsCount) || shouldShowValue(apartment.salonsCount))
            _buildEqualHeightGridRow([
              if (shouldShowValue(apartment.salonsCount))
                Expanded(
                  child: _buildGridBox(
                    iconPath: 'salons.png',
                    title: 'عدد الصالونات',
                    value: apartment.salonsCount.toString(),
                    textAlign: TextAlign.right,
                  ),
                ),
              if (shouldShowValue(apartment.salonsCount) && shouldShowValue(apartment.roomsCount))
                const SizedBox(width: 8),
              if (shouldShowValue(apartment.roomsCount))
                Expanded(
                  child: _buildGridBox(
                    iconPath: 'rooms.png',
                    title: 'عدد الغرف',
                    value: apartment.roomsCount.toString(),
                    textAlign: TextAlign.right,
                  ),
                ),
            ]),
          
          if ((shouldShowValue(apartment.roomsCount) || shouldShowValue(apartment.salonsCount)) &&
              (shouldShowValue(apartment.balconyCount) || shouldShowValue(apartment.isTaras)))
            const SizedBox(height: 8),
            
          if (shouldShowValue(apartment.balconyCount) || shouldShowValue(apartment.isTaras))
            _buildEqualHeightGridRow([
              if (shouldShowValue(apartment.apartmentStatus.name))
                Expanded(
                  child: _buildGridBox(
                    iconPath: 'unit_status.png',
                    title: 'حالة العقار',
                    value: apartment.apartmentStatus.name,
                    textAlign: TextAlign.right,
                  ),
                ),
              if (shouldShowValue(apartment.apartmentStatus.name) && shouldShowValue(apartment.isTaras))
                const SizedBox(width: 8),
              if (shouldShowValue(apartment.isTaras))
                Expanded(
                  child: _buildGridBox(
                    iconPath: 'terrace.png',
                    title: 'تراس',
                    value: 'نعم',
                    textAlign: TextAlign.right,
                  ),
                ),
              if (shouldShowValue(apartment.isTaras) && shouldShowValue(apartment.balconyCount))
                const SizedBox(width: 8),
              if (shouldShowValue(apartment.balconyCount))
                Expanded(
                  child: _buildGridBox(
                    iconPath: 'balcons.png',
                    title: 'عدد البلكونات',
                    value: apartment.balconyCount.toString(),
                    textAlign: TextAlign.right,
                  ),
                ),
            ]),
        ],
      ],
    );
  }

  Widget _buildShareGridRows() {
    if (_itemData == null) return const SizedBox.shrink();
    
    final share = _itemData as Share;
    
    // Helper function to check if value should be shown
    bool shouldShowValue(dynamic value) {
      if (value == null) return false;
      if (value is int && value == 0) return false;
      if (value is double && value == 0.0) return false;
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return false;
        // Check if string represents zero
        final parsed = double.tryParse(trimmed);
        if (parsed != null && parsed == 0.0) return false;
      }
      return true;
    }
    
    // Collect all visible share detail boxes
    List<Widget> shareDetailBoxes = [];
    
    if (shouldShowValue(share.quantity)) {
      shareDetailBoxes.add(_buildGridBox(
        iconPath: 'quantity.png',
        title: 'الأسهم المطروحة',
        value: share.quantity,
        textAlign: TextAlign.right,
      ));
    }
    
    if (shouldShowValue(share.priceKey)) {
      shareDetailBoxes.add(_buildGridBox(
        iconPath: 'price.png',
        title: 'سعر السهم المطروح',
        value: '${_formatNumber(share.priceKey.toString())} ل.س',
        textAlign: TextAlign.right,
      ));
    }
    
    if (shouldShowValue(share.sector.code?.code)) {
      shareDetailBoxes.add(_buildGridBox(
        iconPath: 'section_number.png',
        title: 'رقم المقسم',
        value: share.sector.code?.code ?? '',
        textAlign: TextAlign.right,
      ));
    }
    
    if (shouldShowValue(share.sector.code?.name)) {
      shareDetailBoxes.add(_buildGridBox(
        iconPath: 'sector.png',
        title: 'القطاع',
        value: share.sector.code?.name ?? '',
        textAlign: TextAlign.right,
      ));
    }
    
    if (shouldShowValue(share.region.name)) {
      shareDetailBoxes.add(_buildGridBox(
        iconPath: 'location.png',
        title: 'المنطقة',
        value: share.region.name,
        textAlign: TextAlign.right,
      ));
    }
    
    return Column(
      children: [
        // Build rows of 3 boxes each
        ...List.generate(
          (shareDetailBoxes.length / 3).ceil(),
          (rowIndex) {
            final startIndex = rowIndex * 3;
            final endIndex = (startIndex + 3).clamp(0, shareDetailBoxes.length);
            final rowBoxes = shareDetailBoxes.sublist(startIndex, endIndex);
            
            // Pad with empty space if less than 3 boxes
            while (rowBoxes.length < 3) {
              rowBoxes.add(const SizedBox());
            }
            
            return Column(
              children: [
                if (rowIndex > 0) const SizedBox(height: 8),
                _buildEqualHeightGridRow([
                  Expanded(child: rowBoxes[0]),
                  const SizedBox(width: 8),
                  Expanded(child: rowBoxes[1]),
                  const SizedBox(width: 8),
                  Expanded(child: rowBoxes[2]),
                ]),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectorInformation() {
    if (_itemData == null || _itemData.sector == null) return const SizedBox.shrink();
    
    final sector = _itemData.sector;
    final sectorCode = sector.code?.code ?? '';
    
    // Helper function to check if a value should be shown (not null and not 0)
    bool shouldShowValue(dynamic value) {
      if (value == null) return false;
      if (value is int && value == 0) return false;
      if (value is double && value == 0.0) return false;
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return false;
        // Check if string represents zero
        final parsed = double.tryParse(trimmed);
        if (parsed != null && parsed == 0.0) return false;
      }
      return true;
    }
    
    // Check which values should be shown
    final showOuterArea = shouldShowValue(sector.outerArea);
    final showResidentialArea = shouldShowValue(sector.residentialArea);
    final showCommercialArea = shouldShowValue(sector.commercialArea);
    final showBuildingArea = shouldShowValue(sector.buildingArea);
    final showFloorsNumber = shouldShowValue(sector.floorsNumber);
    final showTotalFloorArea = shouldShowValue(sector.totalFloorArea);
    
    // Debug logging for building area
    Logger.log('🏗️ Sector Building Area Debug:');
    Logger.log('   - Raw value: ${sector.buildingArea}');
    Logger.log('   - Value type: ${sector.buildingArea.runtimeType}');
    Logger.log('   - Should show: $showBuildingArea');
    final showContractor = shouldShowValue(sector.contractor);
    final showEngineers = shouldShowValue(sector.engineers);
    final showDescription = shouldShowValue(sector.description);
    final showOwners = shouldShowValue(sector.owners);
    
    // Check if we have any area details worth showing (first row)
    final hasAreaDetails = showOuterArea || showResidentialArea || showCommercialArea;
    
    // Check if we have any building details worth showing (second row)
    final hasBuildingDetails = showBuildingArea || showFloorsNumber || showTotalFloorArea;
    
    // Check if we have any text details worth showing
    final hasTextDetails = showContractor || showEngineers || showDescription || showOwners;
    
    // If no details should be shown, hide the entire section
    if (!hasAreaDetails && !hasBuildingDetails && !hasTextDetails) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        const SizedBox(height: 16),
        // Title card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E5E5)), // Lighter border color
            borderRadius: BorderRadius.circular(8),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'تفاصيل المقسم $sectorCode',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: Color(0xFF2D2D2D),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Sector details in grid format
        Column(
          children: [
            // First row - Area details (only show if at least one area value exists)
            if (hasAreaDetails) ...[
              _buildEqualHeightGridRow([
                if (showOuterArea)
                  Expanded(
                    child: _buildGridBox(
                      iconPath: 'area.png',
                      title: 'المساحة الخارجية',
                      value: '${sector.outerArea} م²',
                      textAlign: TextAlign.right,
                    ),
                  ),
                if (showOuterArea && showResidentialArea)
                  const SizedBox(width: 8),
                if (showResidentialArea)
                  Expanded(
                    child: _buildGridBox(
                      iconPath: 'building_1.png',
                      title: 'المساحة السكنية',
                      value: '${sector.residentialArea} م²',
                      textAlign: TextAlign.right,
                    ),
                  ),
                if (showResidentialArea && showCommercialArea)
                  const SizedBox(width: 8),
                if (showCommercialArea)
                  Expanded(
                    child: _buildGridBox(
                      iconPath: 'building_type.png',
                      title: 'المساحة التجارية',
                      value: '${sector.commercialArea} م²',
                      textAlign: TextAlign.right,
                    ),
                  ),
              ]),
            ],
              
            // Spacing between rows (only if both rows will be shown)
            if (hasAreaDetails && hasBuildingDetails)
              const SizedBox(height: 8),
              
            // Second row - Building details (only show if at least one building value exists)
            if (hasBuildingDetails) ...[
              _buildEqualHeightGridRow([
                if (showBuildingArea)
                  Expanded(
                    child: _buildGridBox(
                      iconPath: 'area.png',
                      title: 'مساحة البناء',
                      value: '${sector.buildingArea} م²',
                      textAlign: TextAlign.right,
                    ),
                  ),
                if (showBuildingArea && showFloorsNumber)
                  const SizedBox(width: 8),
                if (showFloorsNumber)
                  Expanded(
                    child: _buildGridBox(
                      iconPath: 'floor.png',
                      title: 'عدد الطوابق',
                      value: sector.floorsNumber.toString(),
                      textAlign: TextAlign.right,
                    ),
                  ),
                if (showFloorsNumber && showTotalFloorArea)
                  const SizedBox(width: 8),
                if (showTotalFloorArea)
                  Expanded(
                    child: _buildGridBox(
                      iconPath: 'area.png',
                      title: 'إجمالي مساحة الطوابق',
                      value: '${sector.totalFloorArea} م²',
                      textAlign: TextAlign.right,
                    ),
                  ),
              ]),
            ],
          ],
        ),
        
        // Additional text details
        if (hasTextDetails && (hasAreaDetails || hasBuildingDetails))
          const SizedBox(height: 16),
          
        if (showDescription)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E5E5)), // Lighter border color
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end, // Changed to end for RTL alignment
              children: [
                Container(
                  width: double.infinity,
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'وصف المقسم',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: Color(0xFF2D2D2D),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      sector.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Cairo',
                        color: Color(0xFF555555),
                        height: 1.6,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  double _getBottomButtonsHeight() {
    final authStore = Provider.of<AuthStore>(context, listen: false);
    final isOwner = authStore.userId == _itemData?.userId.toString();
    final isAdmin = authStore.userPrivilege == 'admin' || authStore.userPrivilege == 'owner';
    final canEditDelete = isOwner || isAdmin;
    
    final buttonHeight = 50.0;
    final padding = 20.0;
    final spacing = 12.0;
    final numberOfRows = canEditDelete ? 2 : 1;
    return (numberOfRows * buttonHeight) + ((numberOfRows - 1) * spacing) + (padding * 2);
  }

  Widget _buildBottomActionButtons() {
    if (_itemData == null) return const SizedBox.shrink();
    
    final authStore = Provider.of<AuthStore>(context);
    final isOwner = authStore.userId == _itemData.userId.toString();
    final isAdmin = authStore.userPrivilege == 'admin' || authStore.userPrivilege == 'owner';
    final canEditDelete = isOwner || isAdmin;
    
    // Calculate proper height based on number of button rows
    final buttonHeight = 50.0;
    final padding = 20.0;
    final spacing = 12.0;
    final numberOfRows = canEditDelete ? 2 : 1;
    final totalHeight = (numberOfRows * buttonHeight) + ((numberOfRows - 1) * spacing) + (padding * 2);
    final backgroundHeight = totalHeight * 0.6; // Cover more area to hide content
    
    // Log the permission check
    Logger.log('🔒 Permission Check:');
    Logger.log('   - Current User ID: ${authStore.userId}');
    Logger.log('   - Item User ID: ${_itemData.userId}');
    Logger.log('   - User Privilege: ${authStore.userPrivilege}');
    Logger.log('   - Is Owner: $isOwner');
    Logger.log('   - Is Admin: $isAdmin');
    Logger.log('   - Can Edit/Delete: $canEditDelete');
    
    return Stack(
      children: [
        // Background container that covers content underneath
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: backgroundHeight,
          child: Container(
            color: const Color(0xFFF7F5F2),
          ),
        ),
        // Buttons container
        Container(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Contact owner button (always visible)
              Container(
                height: buttonHeight,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 175, 140, 90),
                      Color.fromARGB(255, 151, 117, 78),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFa47764).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _contactOwner,
                    child: const Center(
                      child: Text(
                        'تواصل مع فريق عقاري',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Owner/Admin-specific buttons
              if (canEditDelete) ...[
                SizedBox(height: spacing),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: buttonHeight,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFECB03D), // Gold
                              Color(0xFFC49000), // Darker Gold
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFECB03D).withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _navigateToEdit,
                            child: const Center(
                              child: Text(
                                'تعديل',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Cairo',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: buttonHeight,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE53E3E),
                              Color(0xFFC53030),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _showDeleteDialog,
                            child: const Center(
                              child: Text(
                                'حذف',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Cairo',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  bool _shouldShowAdditionalDetails(Apartment apartment) {
    return apartment.roomsCount > 0 ||
        apartment.salonsCount > 0 ||
        apartment.balconyCount > 0 ||
        apartment.isTaras > 0;
  }

  // Reaction handling methods
  void _hideReactionPanel() {
    if (_showReactions) {
      setState(() {
        _showReactions = false;
      });
    }
  }

  void _handleReactionButtonTap() {
    setState(() {
      if (_itemData.currentUserReaction == 'like') {
        Logger.log('👆 Reaction button tapped');
        _handleReactionSelected('like'); 
        Logger.log('👍 Removing like reaction');
      } else {
        _handleReactionSelected('like');
        Logger.log('👍 Adding like reaction');
      }
    });
  }

  void _handleReactionButtonLongPress() {
    setState(() {
      _showReactions = !_showReactions;
      Logger.log('🔄 Reaction button long pressed - showing reaction panel');
    });
  }

  Future<void> _handleReactionSelected(String reaction) async {
    final reactionStore = Provider.of<ReactionStore>(context, listen: false);
    final authStore = Provider.of<AuthStore>(context, listen: false);
    final isRemoving = reaction == _itemData.currentUserReaction;
    
    // Log auth info before reaction action
    Logger.log('🔐 Auth Info for Reaction - User ID: ${authStore.userId ?? 'null'}');
    Logger.log('🔐 Auth Info for Reaction - User Privilege: ${authStore.userPrivilege ?? 'null'}');

    if (isRemoving) {
      Logger.log('🗑️ Removing current reaction: ${_itemData.currentUserReaction}');
      Logger.log('🚀 Calling reactionStore.removeReaction...');
      final result = await reactionStore.removeReaction(
        postType: widget.itemType,
        postId: _itemData.id,
      );
      Logger.log('📦 Remove reaction response: $result');

      if (result['success']) {
        Logger.log('✅ Reaction removed successfully');
        setState(() {
          if (widget.itemType == "apartment") {
            _itemData = (_itemData as Apartment).copyWith(
              currentUserReaction: () => null,
              reactionCounts: result['data'] != null && result['data']['reaction_summary'] != null
                  ? ReactionCounts.fromJson(result['data']['reaction_summary'])
                  : null,
            );
          } else {
            _itemData = (_itemData as Share).copyWith(
              currentUserReaction: () => null,
              reactionCounts: result['data'] != null && result['data']['reaction_summary'] != null
                  ? ReactionCounts.fromJson(result['data']['reaction_summary'])
                  : null,
            );
          }
        });
      } else {
      //  ToastHelper.showToast(context, result['message'] ?? 'فشل في إزالة التفاعل', isError: true);
        Logger.error('❌ Failed to remove reaction: ${result['message']}');
      }
    } else {
      // Optimistically update the UI
      final previousReaction = _itemData.currentUserReaction;
      setState(() {
        if (widget.itemType == "apartment") {
          _itemData = (_itemData as Apartment).copyWith(
            currentUserReaction: () => reaction,
          );
        } else {
          _itemData = (_itemData as Share).copyWith(
            currentUserReaction: () => reaction,
          );
        }
      });

      Logger.log('🎯 Selecting reaction: $reaction');
      Logger.log('📱 Item type: ${widget.itemType}');
      Logger.log('🆔 Item ID: ${_itemData.id}');
      Logger.log('👤 Current user reaction: ${_itemData.currentUserReaction}');

      // Avoid API call if the same reaction is clicked again (it should be a removal but as a fallback)
      if (previousReaction == reaction) {
        Logger.log('⏭️ Same reaction clicked, animating only');
        // Optionally trigger animation
        _reactionAnimationController.forward().then((_) => _reactionAnimationController.reverse());
        return;
      }

      Logger.log('🚀 Calling reactionStore.addReaction...');
      final result = await reactionStore.addReaction(
        type: reaction,
        postType: widget.itemType,
        postId: _itemData.id,
      );
      Logger.log('📦 API Response: $result');

      if (result['success']) {
        Logger.log('✅ Reaction added successfully');
        setState(() {
          if (result['data'] != null && result['data']['reaction_summary'] != null) {
            if (widget.itemType == "apartment") {
              _itemData = (_itemData as Apartment).copyWith(
                reactionCounts: ReactionCounts.fromJson(result['data']['reaction_summary']),
              );
            } else {
              _itemData = (_itemData as Share).copyWith(
                reactionCounts: ReactionCounts.fromJson(result['data']['reaction_summary']),
              );
            }
          }
        });
      } else {
       // ToastHelper.showToast(context, result['message'] ?? 'فشل في إضافة التفاعل', isError: true);
        Logger.error('❌ Failed to add reaction: ${result['message']}');
        // Revert optimistic update
        setState(() {
          if (widget.itemType == "apartment") {
            _itemData = (_itemData as Apartment).copyWith(
              currentUserReaction: () => previousReaction,
            );
          } else {
            _itemData = (_itemData as Share).copyWith(
              currentUserReaction: () => previousReaction,
            );
          }
        });
      }
    }
  }

  Future<void> _handleFavoriteToggle() async {
    final reactionStore = Provider.of<ReactionStore>(context, listen: false);
    final authStore = Provider.of<AuthStore>(context, listen: false);
    
    // Log auth info before favorite action
    Logger.log('🔐 Auth Info for Favorite - User ID: ${authStore.userId ?? 'null'}');
    Logger.log('🔐 Auth Info for Favorite - User Privilege: ${authStore.userPrivilege ?? 'null'}');
    Logger.log('⭐ Toggling favorite for ${widget.itemType} ID: ${_itemData.id}');

    final result = await reactionStore.toggleFavorite(
      postType: widget.itemType,
      postId: _itemData.id,
    );
    Logger.log('📦 Toggle favorite response: $result');

    if (result['success']) {
      Logger.log('✅ Favorite toggled successfully');
      final isFavorited = result['data']?['is_favorited'] ?? !_itemData.isFavorited;
      setState(() {
        if (widget.itemType == "apartment") {
          _itemData = (_itemData as Apartment).copyWith(
            isFavorited: isFavorited,
          );
        } else {
          _itemData = (_itemData as Share).copyWith(
            isFavorited: isFavorited,
          );
        }
      });
      final message = isFavorited ? 'تمت الإضافة إلى المفضلة' : 'تمت الإزالة من المفضلة';
     // ToastHelper.showToast(context, message, isError: false);
    } else {
     // ToastHelper.showToast(context, result['message'] ?? 'فشل تحديث المفضلة', isError: true);
      Logger.error('❌ Failed to toggle favorite: ${result['message']}');
    }
  }

  void _shareContent() {
    if (_itemData?.shareButton != null) {
      share_plus.Share.share(_itemData.shareButton);
    } else {
      ToastHelper.showToast(context, 'لا يمكن مشاركة هذا العنصر', isError: true);
    }
  }

  List<String> _getVisibleReactions() {
    final counts = _itemData.reactionCounts;
    final reactionCountsMap = <String, int>{
      'like': counts.likeCount,
      'love': counts.loveCount,
      'wow': counts.wowCount,
      'sad': counts.sadCount,
      'angry': counts.angryCount,
    };

    final sortedReactions = reactionCountsMap.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedReactions.map((entry) => entry.key).take(3).toList();
  }

  int _getReactionCount(String reaction) {
    final counts = _itemData.reactionCounts;
    switch (reaction) {
      case 'like':
        return counts.likeCount;
      case 'love':
        return counts.loveCount;
      case 'wow':
        return counts.wowCount;
      case 'sad':
        return counts.sadCount;
      case 'angry':
        return counts.angryCount;
      default:
        return 0;
    }
  }

  void _showReactionModal() {
    showMaterialModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomBottomSheet(
        title: 'التفاعلات',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _reactionEmojis.entries.where((entry) {
            return _getReactionCount(entry.key) > 0;
          }).map((reactionEntry) {
            final count = _getReactionCount(reactionEntry.key);
            return Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reactionEntry.value,
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

  void _navigateToEdit() async {
    if (widget.itemType == "apartment") {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ApartmentFormPage(
            mode: ApartmentFormMode.update,
            existingApartment: _itemData as Apartment,
          ),
        ),
      );
      
      // If update was successful, reload the details
      if (result == true) {
        _loadItemDetails();
      }
    } else {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShareFormPage(
            mode: ShareFormMode.update,
            existingShare: _itemData as Share,
          ),
        ),
      );
      
      // If update was successful, reload the details
      if (result == true) {
        _loadItemDetails();
      }
    }
  }

  void _showDeleteDialog() {
    showCustomDialog(
      context: context,
      title: 'تأكيد الحذف',
      message: 'هل أنت متأكد من حذف هذا ${widget.itemType == "apartment" ? "العقار" : "السهم"}؟',
      okButtonText: 'حذف',
      cancelButtonText: 'إلغاء',
      isWarning: true,
      onOkPressed: () {
        _deleteItem();
      },
    );
  }

  Future<void> _deleteItem() async {
    setState(() {
      _isLoading = true;
    });

    // Log auth info before delete action
    final authStore = Provider.of<AuthStore>(context, listen: false);
    Logger.log('🔐 Auth Info for Delete - User ID: ${authStore.userId ?? 'null'}');
    Logger.log('🔐 Auth Info for Delete - User Privilege: ${authStore.userPrivilege ?? 'null'}');
    Logger.log('🗑️ Attempting to delete ${widget.itemType} ID: ${_itemData.id}');

    Map<String, dynamic> result;
    try {
      if (widget.itemType == "apartment") {
        result = await _apartmentRepository.deleteApartment(_itemData.id);
      } else {
        result = await _shareRepository.deleteShare(_itemData.id);
      }

      if (result['success']) {
        ToastHelper.showToast(context, result['message'], isError: false);
        // Pop with detailed result to indicate successful deletion
        Navigator.pop(context, {
          'action': 'deleted',
          'itemType': widget.itemType,
          'itemId': _itemData.id,
          'regionId': _itemData.region.id,
        });
      } else {
        ToastHelper.showToast(context, result['message'], isError:true);
      }
    } catch (e) {
      ToastHelper.showToast(context, 'An unexpected error occurred.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _contactOwner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactUsPage(itemData: _itemData),
      ),
    );
  }

  String _formatNumber(String number) {
    if (number.isEmpty) return '';
    return number.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  void _showFullScreenPhotoViewer(int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullScreenPhotoViewer(
            photos: _getPhotos(),
            initialIndex: initialIndex,
            onPhotoChanged: (index) {
              // Update the carousel when user changes photo in full screen
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              setState(() {
                _currentPhotoIndex = index;
              });
            },
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.itemType == "apartment" ? "تفاصيل العقار" : "تفاصيل الأسهم";
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: CustomAppBar(
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
        onLogoPressed: () => Navigator.pop(context),
        title: title,
        showLogo: false,
        titleStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
          color: Color(0xFF1A1A1A), // Adding black color
        ),
      ),
      body: _isLoading
          ? const Center(child: CustomSpinner(size: 50))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Color(0xFF666666),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Cairo',
                          color: Color(0xFF666666),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadItemDetails,
                        child: const Text(
                          'إعادة المحاولة',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: _hideReactionPanel,
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          _buildFixedHeader(),
                          Expanded(
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              child: Column(
                                children: [
                                  _buildImageSlider(),
                                  _buildClickableDots(),
                                  _buildActionButtons(),
                                  // _buildReactionSummary(),
                                  _buildMainDetailsCard(),
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Column(
                                      children: [
                                        if (widget.itemType == "apartment")
                                          _buildApartmentGridRows()
                                        else
                                          _buildShareGridRows(),
                                        _buildSectorInformation(),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: _getBottomButtonsHeight() + 20), // Dynamic space for bottom buttons with extra gap
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Fixed bottom buttons
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildBottomActionButtons(),
                      ),
                      
                      // Floating reaction panel - moved outside the main stack
                      if (_showReactions)
                        _buildFloatingReactionPanel(),
                    ],
                  ),
                ),
    );
  }
} 

class FullScreenPhotoViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  final Function(int) onPhotoChanged;

  const FullScreenPhotoViewer({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.onPhotoChanged,
  });

  @override
  State<FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<FullScreenPhotoViewer> {
  late PageController _fullScreenPageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _fullScreenPageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _fullScreenPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photo viewer
          PageView.builder(
            controller: _fullScreenPageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              widget.onPhotoChanged(index);
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: widget.photos[index].startsWith('assets/')
                      ? Image.asset(
                          widget.photos[index],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/no_photo.jpg',
                              fit: BoxFit.contain,
                            );
                          },
                        )
                      : CachedNetworkImage(
                          imageUrl: widget.photos[index],
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Stack(
                            children: [
                              Shimmer.fromColors(
                                baseColor: Colors.grey[700]!,
                                highlightColor: Colors.grey[500]!,
                                child: Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const Center(
                                child: CustomSpinner(size: 40),
                              ),
                            ],
                          ),
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/images/no_photo.jpg',
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
              );
            },
          ),

          // Close button
          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          // Photo counter (optional)
          if (widget.photos.length > 1)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.photos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 