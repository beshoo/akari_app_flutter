import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pages/webview_page.dart';
import '../services/firebase_messaging_service.dart';
import '../services/secure_storage.dart';
import '../stores/auth_store.dart';
import '../utils/logger.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/custom_bottom_sheet.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  Map<String, dynamic>? user;
  bool loading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _appVersion = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _initialize();
    _loadAppVersion();
  }

  Future<void> _initialize() async {
    final authStore = Provider.of<AuthStore>(context, listen: false); // moved here
    setState(() => loading = true);
    Logger.log('==================== MORE SCREEN INIT ====================');
    // Check what's in secure store
    final userDataStr = await SecureStorage.getUserData('user');
    Logger.log('Secure store user data: $userDataStr');
    Map<String, dynamic>? userData;
    if (userDataStr != null) {
      try {
        userData = jsonDecode(userDataStr);
      } catch (e) {
        Logger.error('Failed to decode user data', e);
      }
    }
    Logger.log('Secure store user keys:  [38;5;8m [48;5;8m${userData?.keys} [0m');
    Logger.log('Secure store user name: ${userData?['name']}');
    final response = authStore.user;
    Logger.log('API response: $response');
    Logger.log('API response keys: ${response?.keys}');
    Logger.log('API response name: ${response?['name']}');
    if (!mounted) return;
    setState(() {
      user = response;
      loading = false;
    });
    Logger.log('=======================================================');
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    Logger.log('packageInfo.version: ${packageInfo.version}, buildNumber: ${packageInfo.buildNumber}');
    if (!mounted) return;
    setState(() {
      _appVersion = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  Future<void> _handleLogout() async {
    await SecureStorage.deleteUserData('user');
    await SecureStorage.deleteToken();
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _handleOpenURL(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        Logger.log("Don't know how to open URI: $url");
      }
    } catch (e) {
      Logger.error('Error opening URL:', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: const Color(0xFFF7F5F2),
        child: Stack(
          children: [
            Scaffold(
              key: _scaffoldKey,
              extendBody: true,
              backgroundColor: Colors.transparent,
              body: Column(
                children: [
                  // AppBar with back button only
                  const CustomAppBar(
                    showBackButton: true,
                    showLogo: true,
                    showFavoritesButton: true,
                    showSearchButton: true,
                    showHelpButton: true,
                    showNotificationButton: true,
                  ),
                  // Header

                  // User profile
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                      padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F5F2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFEAE2DB),
                            radius: 28,
                            child: Image.asset(
                              'assets/images/icons/user.png',
                              width: 32,
                              height: 32,
                              color: const Color(0xFF633e3d),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: loading
                                ? Container(
                                    height: 18,
                                    width: 80,
                                    color: Colors.grey[300],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Cairo',
                                          color: Color(0xFF633e3d),
                                        ),
                                      ),
                                      if (user?['phone'] != null)
                                        Row(
                                          children: isRTL
                                              ? [
                                                  Text(
                                                    user?['phone'] ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFF633e3d),
                                                      fontFamily: 'Cairo',
                                                    ),
                                                  ),
                                                  const Text(
                                                    '+',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFF633e3d),
                                                      fontFamily: 'Cairo',
                                                    ),
                                                  ),
                                                ]
                                              : [
                                                  const Text(
                                                    '+',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFF633e3d),
                                                      fontFamily: 'Cairo',
                                                    ),
                                                  ),
                                                  Text(
                                                    user?['phone'] ?? '',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFF633e3d),
                                                      fontFamily: 'Cairo',
                                                    ),
                                                  ),
                                                ],
                                        ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 32, thickness: 2, color: Color(0xFFE4E4E7)),
                  // Settings list
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _MoreSettingsItem(
                          icon: 'assets/images/icons/support.png',
                          title: 'شرح شامل عن الأسهم',
                            onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WebViewPage(
                                url: 'https://akari.versetech.net/info.html',
                              ),
                            ),
                          ),
                        ),
                        _MoreSettingsItem(
                          icon: 'assets/images/icons/support.png',
                          title: 'أجور تطبيق عقاري دمشق',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WebViewPage(
                                url: 'https://akari.versetech.net/info.html#app-fees',
                              ),
                            ),
                          ),
                        ),
                      /*   if (user != null && user?['privilege'] == 'admin')
                          _MoreSettingsItem(
                            icon: 'assets/images/icons/user.png',
                            title: 'المستخدمين',
                            onTap: () => Navigator.pushNamed(context, '/users_list'),
                          ),
                        if (user != null && user?['privilege'] == 'admin')
                          _MoreSettingsItem(
                            icon: 'assets/images/icons/bulk_messages.png',
                            title: 'رسائل جماعية',
                            onTap: () => Navigator.pushNamed(context, '/bulk_messages'),
                          ), */
                        _MoreSettingsItem(
                          icon: 'assets/images/icons/gold.png',
                          title: 'الحساب الذهبي',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WebViewPage(
                                url: 'https://akari.versetech.net/golden-account.html',
                              ),
                            ),
                          ),
                        ),
                        _MoreSettingsItemWithIcon(
                          icon: Icons.star,
                          title: 'المفضلة',
                          onTap: () => Navigator.pushNamed(context, '/favorites'),
                        ),
                        _MoreSettingsItem(
                          icon: 'assets/images/icons/notifications.png',
                          title: 'مركز الإشعارات',
                          onTap: () {
                            Navigator.pushNamed(context, '/notifications');
                          },
                        ),
                        NotificationPermissionSwitcher(),
                        _MoreSettingsItem(
                          icon: 'assets/images/icons/support.png',
                          title: 'المساعدة و الدعم الفني',
                          onTap: () => Navigator.pushNamed(context, '/support_page'),
                        ),
                        _MoreSettingsItemWithIcon(
                          icon: Icons.facebook,
                          title: 'صفحة الفيسبوك',
                          onTap: () => _handleOpenURL('https://www.facebook.com/akari.damascus'),
                        ),
                        _MoreSettingsItem(
                          icon: 'assets/images/icons/privacy.png',
                          title: 'سياسة الخصوصية',
                                            onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WebViewPage(
                                url: 'https://akari.versetech.net/privacy-policy.html',
                                title: 'سياسة الخصوصية',
                              ),
                            ),
                          ),
                        ),
                        _MoreSettingsItem(
                          icon: 'assets/images/icons/terms.png',
                          title: 'شروط الاستخدام',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WebViewPage(
                                url: 'https://akari.versetech.net/terms.html',
                                title: 'شروط الاستخدام',
                              ),
                            ),
                          ),
                        ),
                        _LogoutInnerItem(
                          icon: 'assets/images/icons/logout.png',
                          title: 'تسجيل الخروج',
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => CustomBottomSheet(
                              title: '',
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 16),
                                  Text(
                                    'هل أنت متأكد من تسجيل الخروج؟',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey[300],
                                          foregroundColor: Colors.black,
                                        ),
                                        child: const Text('إلغاء'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _handleLogout();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(255, 148, 23, 23),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('تأكيد'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            'رقم الإصدار $_appVersion ($_buildNumber)',
                            style: const TextStyle(
                              color: Color.fromARGB(255, 63, 63, 63),
                              fontSize: 14,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                        // Add extra bottom padding for bottom navigation bar
                        const SizedBox(height: 85),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Background fill behind navigation bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 75 + MediaQuery.of(context).viewPadding.bottom, // Navigation bar height + margin + safe area
                color: const Color(0xFFF7F5F2), // The screen's background color
              ),
            ),
            // Bottom navigation bar
            Align(
              alignment: Alignment.bottomCenter,
              child: CustomBottomNavBar(
                currentIndex: 5, // More tab index (المزيد)
                onTap: (index) {
                  // Navigation is handled by CustomBottomNavBar
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreSettingsItem extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback onTap;
  const _MoreSettingsItem({required this.icon, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFEAE2DB),
        child: Image.asset(icon, width: 24, height: 24, color: const Color(0xFF633e3d)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF633e3d),
          fontFamily: 'Cairo',
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.chevron_right, color: Color(0xFF633e3d)),
          SizedBox(width: 10),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}

class _MoreSettingsItemWithIcon extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _MoreSettingsItemWithIcon({required this.icon, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFEAE2DB),
        child: Icon(icon, color: const Color(0xFF633e3d), size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF633e3d),
          fontFamily: 'Cairo',
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.chevron_right, color: Color(0xFF633e3d)),
          SizedBox(width: 10),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}

class _LogoutInnerItem extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback onTap;
  const _LogoutInnerItem({required this.icon, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: const Color.fromARGB(255, 121, 20, 20),
        child: Image.asset(icon, width: 24, height: 24, color: Colors.white),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: 'Cairo',
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.chevron_right, color: Colors.white),
          SizedBox(width: 10),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      tileColor: const Color.fromARGB(255, 121, 20, 20),
    );
  }
}

class NotificationPermissionSwitcher extends StatefulWidget {
  const NotificationPermissionSwitcher({super.key});

  @override
  State<NotificationPermissionSwitcher> createState() => _NotificationPermissionSwitcherState();
}

class _NotificationPermissionSwitcherState extends State<NotificationPermissionSwitcher> {
  bool _enabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final enabled = await FirebaseMessagingService.isNotificationEnabled();
    setState(() {
      _enabled = enabled;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _loading = true);
    if (value) {
      await FirebaseMessagingService.instance.enableNotifications();
    } else {
      await FirebaseMessagingService.instance.disableNotifications();
    }
    setState(() {
      _enabled = value;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFEAE2DB),
        child: Image.asset('assets/images/icons/notifications.png', width: 24, height: 24, color: const Color(0xFF633e3d)),
      ),
      title: Text(
        _enabled ? 'إيقاف الإشعارات' : 'تفعيل الإشعارات',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF633e3d),
          fontFamily: 'Cairo',
        ),
      ),
      trailing: _loading
          ? SizedBox(
              width: 40, // match the Row width when checkbox is shown
              height: 24,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 40),
                Checkbox(
                  value: _enabled,
                  onChanged: (val) {
                    if (val != null) _toggle(val);
                  },
                  activeColor: const Color(0xFF633e3d),
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),

              ],
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: _loading ? null : () => _toggle(!_enabled),
    );
  }
} 