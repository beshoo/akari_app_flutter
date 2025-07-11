import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.onNotificationPressed,
    this.onSearchPressed,
    this.onFavoritesPressed,
    this.onHelpPressed,
    this.showBackButton = true,
    this.onBackPressed,
    this.title,
  });

  final VoidCallback? onNotificationPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onFavoritesPressed;
  final VoidCallback? onHelpPressed;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final String? title;

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
              if (title != null) 
                Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8C7A6A),
                  ),
                )
              else
              Image.asset(
                'assets/images/logo.png',
                height: 35,
              ),
            ],
          ),

          // This will be on the left in RTL
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.star_border_outlined,
                  color: Color(0xFF8C7A6A),
                ),
                onPressed: onFavoritesPressed,
              ),
              IconButton(
                icon: const Icon(
                  Icons.search,
                  color: Color(0xFF8C7A6A),
                ),
                onPressed: onSearchPressed,
              ),
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_outlined,
                  color: Color(0xFF8C7A6A),
                ),
                onPressed: onNotificationPressed,
              ),
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
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 