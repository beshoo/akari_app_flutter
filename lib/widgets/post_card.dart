import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../data/models/share_model.dart';
import '../stores/reaction_store.dart';
import '../stores/auth_store.dart';
import '../utils/toast_helper.dart';
import 'custom_bottom_sheet.dart';
import './post_card_data.dart';

class PostCard extends StatefulWidget {
  final PostCardData postData;
  final Function(PostCardData)? onPostUpdated;
  final ScrollController? scrollController;

  const PostCard({
    super.key,
    required this.postData,
    this.onPostUpdated,
    this.scrollController,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
  // === Action Button Size Controls ===
  static const double _actionButtonFontSize = 17;
  static const double _actionButtonIconSize = 22;

  bool _showReactions = false;
  late PostCardData _currentPostData;
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
    'like': 'أعجبني',
    'love': 'أحببته',
    'wow': 'أدهشني',
    'sad': 'أحزنني',
    'angry': 'أغضبني',
  };

  @override
  void initState() {
    super.initState();
    _currentPostData = widget.postData;
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
    
    // Add scroll listener to hide reaction panel on scroll
    if (widget.scrollController != null) {
      widget.scrollController!.addListener(_onScroll);
    }
  }
  
  void _onScroll() {
    if (_showReactions) {
      setState(() {
        _showReactions = false;
      });
    }
  }

  void _hideReactionPanel() {
    if (_showReactions) {
      setState(() {
        _showReactions = false;
      });
    }
  }

  @override
  void dispose() {
    if (widget.scrollController != null) {
      widget.scrollController!.removeListener(_onScroll);
    }
    _reactionAnimationController.dispose();
    super.dispose();
  }

  // Color constants
  static const Color _toastColor = Color(0xFF1F2937);
  static const Color _goldColor = Color(0xFFEAE2DB);
  static const Color _grayColor = Color(0xFF374151);

  // Gradient definitions
  static const List<Color> _badgeGradient = [
    Color(0xFF633E3D),
    Color(0xFF774B46),
    Color(0xFF8D5E52),
    Color(0xFFA47764),
    Color(0xFFBDA28C),
  ];

  static const List<Color> _approvalGradient = [
    Color(0xFFE3A001),
    Color(0xFFB87005),
    Color(0xFF95560B),
    Color(0xFF7A460D),
    Color(0xFF7A460D),
  ];

  static const List<Color> _closedGradient = [
    Color(0xFF633E3D),
    Color(0xDB774B46),
    Color(0xA18D5E52),
    Color(0x5C000000),
    Color(0x1B000000),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer2<ReactionStore, AuthStore>(
      builder: (context, reactionStore, authStore, child) {
        return GestureDetector(
          onTap: () => _hideReactionPanel(),
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              Column(
                children: [
                  // Main card
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 350,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _toastColor.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Background image layer
                        _buildBackgroundImage(),
                        
                        // Status badges layer
                        _buildStatusBadges(authStore),
                        
                        // Content overlay
                        _buildContentOverlay(),
                        
                        // Closed deal overlay (on top of everything)
                        if (_currentPostData.isClosed) _buildClosedOverlay(),
                      ],
                    ),
                  ),
                  
                  // Reaction summary section
                  if (_currentPostData.reactionCounts.totalCount > 0)
                    _buildReactionSummary(),
                  
                  // Action buttons row
                  _buildActionButtons(reactionStore, authStore),
                ],
              ),
              
              // Floating reaction panel positioned above action buttons
              if (_showReactions) _buildFloatingReactionPanel(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackgroundImage() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: _currentPostData.imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: Image.asset(
              'assets/images/no_photo.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadges(AuthStore authStore) {
    return Positioned(
      top: 12,
      left: 12,
      right: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side badges
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction type badge
              _buildBadge(
                _currentPostData.transactionTypeText,
                _badgeGradient,
              ),
              
              // Approval status badge
              if (_shouldShowApprovalBadge(authStore))
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: _buildBadge(
                    'قيد المراجعة',
                    _approvalGradient,
                  ),
                ),
            ],
          ),
          
          // Right side badges - ID badge aligned to top
          _buildBadge(
            _currentPostData.badgeId,
            _badgeGradient,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, List<Color> gradient) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildClosedOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: _closedGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Text(
            _currentPostData.closedText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 60,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(2, 2),
                  blurRadius: 4,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        constraints: BoxConstraints(
          minHeight: 80, // Minimum height
          maxHeight: _currentPostData.infoRows.length <= 4 ? 180 : 320, // Adaptive height
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 71, 47, 45).withValues(alpha: 0.9),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Use minimum space needed
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Sector title
                Expanded(
                  child: Text(
                    _currentPostData.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Verification icon
                if (_currentPostData.isUserVerified)
                  Image.asset(
                    'assets/images/icons/gold.png',
                    width: 28,
                    height: 28,
                    color: _goldColor,
                  ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Subtitle
            Text(
              _currentPostData.subtitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
            
            const SizedBox(height: 6),
            
            // Information rows - auto-adjustable height
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
              children: _currentPostData.infoRows
                  .map((info) => _buildInfoRow(info.iconName, info.text))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String iconName, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Image.asset(
            'assets/images/icons/$iconName',
            width: 20,
            height: 20,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionSummary() {
    final reactions = _getVisibleReactions();
    return GestureDetector(
      onTap: () => _showReactionModal(),
      child: Container(
        padding: const EdgeInsets.only(left: 12, top: 4, bottom: 0, right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Overlapping reaction emojis
            if (reactions.isNotEmpty)
              Row(
                children: [
                  for (int i = 0; i < reactions.length; i++)
                    Transform.translate(
                      offset: Offset(5.0 * i, 0), // More overlap like Facebook
                      child: Container(
                        decoration: BoxDecoration(
                         // color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Text(
                          _reactionEmojis[reactions[i]]!,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                ],
              ),
            if (reactions.isNotEmpty)
              const SizedBox(width: 1), // Fixed flexible spacing after overlapped emojis
            // Small count
            Text(
              '${_currentPostData.reactionCounts.totalCount}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _grayColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ReactionStore reactionStore, AuthStore authStore) {
    return Container(
      // Removed the top border line
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          // Like/Reaction button
          Expanded(
            child: GestureDetector(
              onTap: () => _handleReactionButtonTap(),
              onLongPress: () => _handleReactionButtonLongPress(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _getCurrentReactionIcon(size: _actionButtonIconSize),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _getCurrentReactionText(),
                        style: TextStyle(
                          fontSize: _actionButtonFontSize,
                          fontWeight: FontWeight.w500,
                          color: _grayColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Share button
          Expanded(
            child: _buildActionButton(
              icon: FaIcon(FontAwesomeIcons.shareNodes, size: _actionButtonIconSize),
              text: 'شارك',
              onTap: () => _shareContent(),
            ),
          ),
          // Favorite button
          Expanded(
            child: _buildActionButton(
              icon: FaIcon(
                _currentPostData.isFavorited
                    ? FontAwesomeIcons.solidStar
                    : FontAwesomeIcons.star,
                size: _actionButtonIconSize,
                color: _currentPostData.isFavorited ? Colors.amber : _grayColor,
              ),
              text: 'مفضلة',
              onTap: () => _toggleFavorite(reactionStore),
            ),
          ),
          // Views counter
          Expanded(
            child: _buildActionButton(
              icon: Image.asset(
                'assets/images/icons/view.png',
                width: _actionButtonIconSize,
                height: _actionButtonIconSize,
                color: _grayColor,
              ),
              text: '${_currentPostData.views}',
              onTap: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required Widget icon,
    required String text,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: _actionButtonFontSize,
                  fontWeight: FontWeight.w500,
                  color: _grayColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingReactionPanel() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardMargin = 24.0; // Total horizontal margin of the card (12px each side)
    final availableWidth = screenWidth - cardMargin;
    final buttonWidth = availableWidth / 4; // 4 equal buttons
    final panelWidth = 200.0; // Approximate panel width
    
    // Calculate left position - you can try different values:
    //double leftPosition = 8.0;   // Far left edge
    // double leftPosition = 40.0;  // A bit more to the right
     double leftPosition = 150.0;  // Even more to the right
    
    return Positioned(
      bottom: 50, // Position above action buttons
      left: leftPosition,
      child: GestureDetector(
        onTap: () {}, // Prevent taps on the panel from closing it
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30), // Facebook-style rounded
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _reactionEmojis.entries.map((entry) {
              final isSelected = _currentPostData.currentUserReaction == entry.key;
              return GestureDetector(
                onTap: () => _selectReaction(entry.key),
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
                              ? const Color(0xFF1877F2).withValues(alpha: 0.1) // Facebook blue tint
                              : Colors.transparent, // No background
                          shape: BoxShape.circle, // Perfect circle (50% radius)
                        ),
                        child: Center(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: isSelected ? 28 : 24, // Slightly bigger when selected
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
      ),
    );
  }

  // Helper methods
  bool _shouldShowApprovalBadge(AuthStore authStore) {
    final isAdminOrOwner = authStore.userPrivilege == 'admin' || 
                          authStore.userPrivilege == 'owner';
    return isAdminOrOwner && _currentPostData.isUnderReview;
  }

  bool _shouldShowOwnerRow(AuthStore authStore) {
    return authStore.userPrivilege == 'admin' || 
           authStore.userPrivilege == 'owner';
  }

  List<String> _getVisibleReactions() {
    final counts = _currentPostData.reactionCounts;
    final reactionCounts = <String, int>{
      'like': counts.likeCount,
      'love': counts.loveCount,
      'wow': counts.wowCount,
      'sad': counts.sadCount,
      'angry': counts.angryCount,
    };
    
    // Filter reactions with count > 0 and sort by count (descending)
    final sortedReactions = reactionCounts.entries
        .where((entry) => entry.value > 0)
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedReactions.map((entry) => entry.key).toList();
  }

  Widget _getCurrentReactionIcon({double size = 16}) {
    return SizedBox(
      width: size + 2, // Fixed width to prevent layout shifts
      height: size + 2, // Fixed height to prevent layout shifts
      child: Center(
        child: _currentPostData.currentUserReaction != null
            ? Text(
                _reactionEmojis[_currentPostData.currentUserReaction!]!,
                style: TextStyle(fontSize: size - 2), // Slightly smaller to fit better
              )
            : FaIcon(
                FontAwesomeIcons.thumbsUp,
                size: size,
                color: _grayColor,
              ),
      ),
    );
  }

  String _getCurrentReactionText() {
    if (_currentPostData.currentUserReaction != null) {
      return _reactionNames[_currentPostData.currentUserReaction!]!;
    }
    return 'إعجاب';
  }

  void _handleReactionButtonTap() async {
    if (_currentPostData.currentUserReaction == 'like') {
      // User already liked it, remove the like
      await _removeCurrentReaction();
    } else {
      // Send like reaction directly (Facebook behavior)
      await _selectReaction('like');
    }
  }

  void _handleReactionButtonLongPress() {
    // Always show reaction panel on long press
    setState(() {
      _showReactions = true;
    });
  }

  Future<void> _removeCurrentReaction() async {
    final reactionStore = Provider.of<ReactionStore>(context, listen: false);
    
    final result = await reactionStore.removeReaction(
      postType: _currentPostData.postType,
      postId: _currentPostData.id,
    );

    if (result['success']) {
      // Update state based on API response
      if (result['data'] != null && result['data']['reaction_summary'] != null) {
        _currentPostData = _currentPostData.withReaction(null, result['data']['reaction_summary']);
      } else {
        // Fallback: manually remove reaction
        _currentPostData = _currentPostData.withManuallyDecrementedReaction(_currentPostData.currentUserReaction!);
      }
      
      if (widget.onPostUpdated != null) {
        widget.onPostUpdated!(_currentPostData);
      }
    } else {
      // Show error message if remove reaction failed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'فشل في إزالة التفاعل'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    // Note: No toast message for successful reactions as requested
  }

  Future<void> _selectReaction(String reaction) async {
    final reactionStore = Provider.of<ReactionStore>(context, listen: false);
    
    _hideReactionPanel(); // Hide panel immediately

    if (reaction == _currentPostData.currentUserReaction) {
      _reactionAnimationController.forward().then((_) {
        _reactionAnimationController.reverse();
      });
      return;
    }

    _reactionAnimationController.forward().then((_) {
      _reactionAnimationController.reverse();
    });

    final result = await reactionStore.addReaction(
      type: reaction,
      postType: _currentPostData.postType,
      postId: _currentPostData.id,
    );

    if (kDebugMode) {
      print('🎯 Reaction result: $result');
      print('🎯 Result success: ${result['success']}');
      print('🎯 Result data: ${result['data']}');
    }

    if (result['success']) {
      // Update state based on API response
      if (result['data'] != null && result['data']['reaction_summary'] != null) {
        _currentPostData = _currentPostData.withReaction(reaction, result['data']['reaction_summary']);
      } else {
        if (kDebugMode) {
          print('⚠️ No reaction_summary found, using fallback');
        }
        // Fallback: manually update reaction
        _currentPostData = _currentPostData.withReactionCounts(_updateReactionCounts(reaction));
      }
      
      if (widget.onPostUpdated != null) {
        widget.onPostUpdated!(_currentPostData);
      }
    } else {
      // Show error message if reaction failed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'فشل في إضافة التفاعل'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    // Note: No toast message for successful reactions as requested
  }

  Map<String, dynamic> _updateReactionCounts(String newReaction) {
    final counts = _currentPostData.reactionCounts;
    final currentReaction = _currentPostData.currentUserReaction;
    
    Map<String, int> newCounts = {
      'like_count': counts.likeCount,
      'love_count': counts.loveCount,
      'wow_count': counts.wowCount,
      'sad_count': counts.sadCount,
      'angry_count': counts.angryCount,
      'total_count': counts.totalCount,
    };

    // Remove old reaction if exists
    if (currentReaction != null) {
      newCounts['${currentReaction}_count'] = newCounts['${currentReaction}_count']! - 1;
      newCounts['total_count'] = newCounts['total_count']! - 1;
    }

    // Add new reaction
    newCounts['${newReaction}_count'] = newCounts['${newReaction}_count']! + 1;
    newCounts['total_count'] = newCounts['total_count']! + 1;

    return newCounts;
  }

  Map<String, dynamic> _decrementReactionCounts(String removedReaction) {
    final counts = _currentPostData.reactionCounts;
    
    Map<String, int> newCounts = {
      'like_count': counts.likeCount,
      'love_count': counts.loveCount,
      'wow_count': counts.wowCount,
      'sad_count': counts.sadCount,
      'angry_count': counts.angryCount,
      'total_count': counts.totalCount,
    };

    // Remove the reaction
    newCounts['${removedReaction}_count'] = (newCounts['${removedReaction}_count']! - 1).clamp(0, double.infinity).toInt();
    newCounts['total_count'] = (newCounts['total_count']! - 1).clamp(0, double.infinity).toInt();

    return newCounts;
  }

  void _updateFromReactionSummary(Map<String, dynamic> reactionSummary, [String? newUserReaction]) {
    if (kDebugMode) {
      print('📊 Updating reaction summary: $reactionSummary');
      print('🔄 New user reaction: $newUserReaction');
    }
    
    setState(() {
      _currentPostData = _currentPostData.withReaction(newUserReaction, reactionSummary);
    });
    
    if (kDebugMode) {
      print('✅ Share updated - Current user reaction: ${_currentPostData.currentUserReaction}');
      print('✅ Total reactions: ${_currentPostData.reactionCounts.totalCount}');
    }
  }

  void _toggleFavorite(ReactionStore reactionStore) async {
    final result = await reactionStore.toggleFavorite(
      postType: _currentPostData.postType,
      postId: _currentPostData.id,
    );

    if (result['success']) {
      setState(() {
        _currentPostData = _currentPostData.withFavorite(!_currentPostData.isFavorited);
      });
      
      if (widget.onPostUpdated != null) {
        widget.onPostUpdated!(_currentPostData);
      }
    } else {
      if (mounted) {
        ToastHelper.showToast(
          context,
          result['message'] ?? 'فشل في تحديث المفضلة',
          isError: true,
        );
      }
    }
  }

  void _shareContent() {
    share_plus.Share.share(_currentPostData.shareButtonText);
  }

  void _showReactionModal() {
    if (kDebugMode) {
      print('🔥 Opening reaction modal bottom sheet');
    }
    
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
    final counts = _currentPostData.reactionCounts;
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
} 