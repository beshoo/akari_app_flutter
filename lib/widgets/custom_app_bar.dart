import 'package:flutter/material.dart';
import 'package:akari_app/pages/webview_page.dart';
import 'package:akari_app/stores/notification_store.dart';
import 'package:provider/provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.showFavoritesButton = false,
    this.onFavoritesPressed,
    this.showSearchButton = false,
    this.onSearchPressed,
    this.showNotificationButton = false,
    this.onNotificationPressed,
    this.showHelpButton = false,
    this.onHelpPressed,
    this.showSortButton = false,
    this.onSortPressed,
    this.showAddAdButton = false,
    this.onAddAdPressed,
    this.showDeleteNotificationsButton = false,
    this.onDeleteNotificationsPressed,
    this.showBackButton = true,
    this.onBackPressed,
    this.title,
    this.showLogo = true,
    this.titleStyle,
    this.onLogoPressed,
    this.onlyText = false,
    this.notificationCount,
  });

  /// Which action buttons to show
  final bool showFavoritesButton;
  final bool showSearchButton;
  final bool showNotificationButton;
  final bool showHelpButton;
  final bool showSortButton;
  final bool showAddAdButton;
  final bool showDeleteNotificationsButton;

  /// Optional overrides for action handlers
  final VoidCallback? onFavoritesPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onHelpPressed;
  final VoidCallback? onSortPressed;
  final VoidCallback? onAddAdPressed;
  final VoidCallback? onDeleteNotificationsPressed;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final String? title;
  final bool showLogo;
  final TextStyle? titleStyle;
  final VoidCallback? onLogoPressed;
  final bool onlyText;
  final int? notificationCount;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final logoHeight = isSmallScreen ? 28.0 : 35.0;
    final int effectiveNotificationCount = notificationCount ?? Provider.of<NotificationStore>(context).notificationCount;
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: const Color(0xFFF7F5F2),
      surfaceTintColor: const Color(0xFFF7F5F2),
      title: Row(
        children: [
          if (showBackButton)
            GestureDetector(
              onTap: onBackPressed ?? () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: const Icon(
                Icons.arrow_back_ios,
                color: Color(0xFF8C7A6A),
                size: 20,
              ),
            ),
          if (showBackButton) SizedBox(width: isSmallScreen ? 4 : 8),
          if (showLogo)
            GestureDetector(
              onTap: onLogoPressed ?? () {
                final ModalRoute<Object?>? route = ModalRoute.of(context);
                if (route != null && route.settings.name != '/home' && Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: Image.asset(
                'assets/images/logo.png',
                height: logoHeight,
                fit: BoxFit.contain,
              ),
            ),
          if (showLogo && title != null) SizedBox(width: isSmallScreen ? 8 : 12),
          if (title != null)
            Expanded(
              child: Text(
                title!,
                style: titleStyle ?? TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8C7A6A),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          if (!onlyText) const Spacer(),
          // Action buttons
          if (showFavoritesButton)
            IconButton(
              icon: const Icon(
                Icons.star_border_outlined,
                color: Color(0xFF8C7A6A),
              ),
              onPressed: onFavoritesPressed ?? () {
                // Default: navigate to favorites page (replace with your route)
                Navigator.pushNamed(context, '/favorites');
              },
              iconSize: isSmallScreen ? 20 : 24,
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              constraints: BoxConstraints(
                minWidth: isSmallScreen ? 32 : 48,
                minHeight: isSmallScreen ? 32 : 48,
              ),
            ),
          if (showSearchButton)
            IconButton(
              icon: const Icon(
                Icons.search,
                color: Color(0xFF8C7A6A),
              ),
              onPressed: onSearchPressed ?? () {
                Navigator.pushNamed(context, '/search');
              },
              iconSize: isSmallScreen ? 20 : 24,
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              constraints: BoxConstraints(
                minWidth: isSmallScreen ? 32 : 48,
                minHeight: isSmallScreen ? 32 : 48,
              ),
            ),
          if (showSortButton)
            IconButton(
              icon: const Icon(
                Icons.sort,
                color: Color(0xFF8C7A6A),
              ),
              onPressed: onSortPressed,
              iconSize: isSmallScreen ? 20 : 24,
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              constraints: BoxConstraints(
                minWidth: isSmallScreen ? 32 : 48,
                minHeight: isSmallScreen ? 32 : 48,
              ),
            ),
          if (showNotificationButton)
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_outlined,
                    color: Color(0xFF8C7A6A),
                  ),
                  onPressed: onNotificationPressed ?? () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                  iconSize: isSmallScreen ? 20 : 24,
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  constraints: BoxConstraints(
                    minWidth: isSmallScreen ? 32 : 48,
                    minHeight: isSmallScreen ? 32 : 48,
                  ),
                ),
                if (effectiveNotificationCount > 0)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 167, 43, 34),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          effectiveNotificationCount > 99 ? '99+' : effectiveNotificationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          if (showHelpButton)
            SizedBox(
              width: isSmallScreen ? 32 : 36,
              height: isSmallScreen ? 32 : 36,
              child: Material(
                color: const Color(0xFFEBE5DB),
                shape: const CircleBorder(),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.question_mark,
                    color: const Color(0xFF8C7A6A),
                    size: isSmallScreen ? 16 : 20,
                  ),
                  onPressed: onHelpPressed ?? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WebViewPage(
                          url: 'https://akari.versetech.net/info.html',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          if (showAddAdButton)
            SizedBox(
              width: isSmallScreen ? 100 : 140,
              child: Padding(
                padding: EdgeInsets.only(right: isSmallScreen ? 4.0 : 8.0),
                child: DecoratedBox(
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: onAddAdPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 12, 
                        vertical: 4
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isSmallScreen ? 'أضف إعلان' : 'أضف إعلانك الآن',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontSize: isSmallScreen ? 11 : 13,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          if (showDeleteNotificationsButton)
            SizedBox(
              width: isSmallScreen ? 100 : 140,
              child: Padding(
                padding: EdgeInsets.only(right: isSmallScreen ? 4.0 : 8.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFA72B22),
                        Color(0xFFBDA28C),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: onDeleteNotificationsPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 12, 
                        vertical: 4
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isSmallScreen ? 'حذف الإشعارات' : 'حذف الإشعارات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontSize: isSmallScreen ? 11 : 13,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 