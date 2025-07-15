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
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      backgroundColor: const Color(0xFFF7F5F2), // A color similar to the image
      surfaceTintColor: const Color(0xFFF7F5F2),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // This will be on the right in RTL
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              if (showBackButton) const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showLogo)
                    GestureDetector(
                      onTap: onLogoPressed,
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 35,
                      ),
                    ),
                  if (title != null) ...[
                    if (showLogo) const SizedBox(height: 2),
                    Text(
                      title!,
                      style: titleStyle ?? const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8C7A6A),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // This will be on the left in RTL
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onFavoritesPressed != null)
                IconButton(
                  icon: const Icon(
                    Icons.star_border_outlined,
                    color: Color(0xFF8C7A6A),
                  ),
                  onPressed: onFavoritesPressed,
                ),
              if (onSearchPressed != null)
                IconButton(
                  icon: const Icon(
                    Icons.search,
                    color: Color(0xFF8C7A6A),
                  ),
                  onPressed: onSearchPressed,
                ),
              if (onSortPressed != null)
                IconButton(
                  icon: const Icon(
                    Icons.sort,
                    color: Color(0xFF8C7A6A),
                  ),
                  onPressed: onSortPressed,
                ),
              if (onNotificationPressed != null)
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_outlined,
                    color: Color(0xFF8C7A6A),
                  ),
                  onPressed: onNotificationPressed,
                ),
              if (onHelpPressed != null)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBE5DB),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.question_mark,
                      color: Color(0xFF8C7A6A),
                      size: 20,
                    ),
                    onPressed: onHelpPressed,
                  ),
                ),
              if (showAddAdButton)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'أضف إعلانك الآن',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 