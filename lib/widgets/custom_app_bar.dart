import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.onNotificationPressed,
    this.onSearchPressed,
    this.onFavoritesPressed,
    this.onHelpPressed,
    this.onSortPressed,
    this.showAddAdButton = false,
    this.onAddAdPressed,
    this.showBackButton = true,
    this.onBackPressed,
    this.title,
    this.showLogo = true,
    this.titleStyle,
    this.onLogoPressed,
  });

  final VoidCallback? onNotificationPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onFavoritesPressed;
  final VoidCallback? onHelpPressed;
  final VoidCallback? onSortPressed;
  final bool showAddAdButton;
  final VoidCallback? onAddAdPressed;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final String? title;
  final bool showLogo;
  final TextStyle? titleStyle;
  final VoidCallback? onLogoPressed;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final logoHeight = isSmallScreen ? 28.0 : 35.0;
    
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: const Color(0xFFF7F5F2), // A color similar to the image
      surfaceTintColor: const Color(0xFFF7F5F2),
      title: Row(
        children: [
          // This will be on the right in RTL
          if (showBackButton)
            GestureDetector(
              onTap: onBackPressed ??
                  () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
              child: const Icon(
                Icons.arrow_back_ios, // This is <, but renders as > in RTL
                color: Color(0xFF8C7A6A),
                size: 20,
              ),
            ),
          if (showBackButton) SizedBox(width: isSmallScreen ? 4 : 8),
          if (showLogo)
            GestureDetector(
              onTap: onLogoPressed,
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
          
          const Spacer(),
          
          // Icons on the left side (RTL)
          if (onFavoritesPressed != null)
            IconButton(
              icon: const Icon(
                Icons.star_border_outlined,
                color: Color(0xFF8C7A6A),
              ),
              onPressed: onFavoritesPressed,
              iconSize: isSmallScreen ? 20 : 24,
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              constraints: BoxConstraints(
                minWidth: isSmallScreen ? 32 : 48,
                minHeight: isSmallScreen ? 32 : 48,
              ),
            ),
          if (onSearchPressed != null)
            IconButton(
              icon: const Icon(
                Icons.search,
                color: Color(0xFF8C7A6A),
              ),
              onPressed: onSearchPressed,
              iconSize: isSmallScreen ? 20 : 24,
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              constraints: BoxConstraints(
                minWidth: isSmallScreen ? 32 : 48,
                minHeight: isSmallScreen ? 32 : 48,
              ),
            ),
          if (onSortPressed != null)
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
          if (onNotificationPressed != null)
            IconButton(
              icon: const Icon(
                Icons.notifications_none_outlined,
                color: Color(0xFF8C7A6A),
              ),
              onPressed: onNotificationPressed,
              iconSize: isSmallScreen ? 20 : 24,
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              constraints: BoxConstraints(
                minWidth: isSmallScreen ? 32 : 48,
                minHeight: isSmallScreen ? 32 : 48,
              ),
            ),
          if (onHelpPressed != null)
            Container(
              width: isSmallScreen ? 32 : 36,
              height: isSmallScreen ? 32 : 36,
              decoration: const BoxDecoration(
                color: Color(0xFFEBE5DB),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.question_mark,
                  color: const Color(0xFF8C7A6A),
                  size: isSmallScreen ? 16 : 20,
                ),
                onPressed: onHelpPressed,
              ),
            ),
          // Add button with fixed width
          if (showAddAdButton)
            Container(
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
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 