import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/custom_app_bar.dart';
import '../utils/logger.dart';
import '../widgets/custom_dialog.dart';
import '../services/api_service.dart';
import '../utils/toast_helper.dart';
import '../data/models/notification_model.dart';
import '../widgets/custom_spinner.dart';
import '../stores/notification_store.dart';
import 'property_details_page.dart';
import '../services/firebase_messaging_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationItem> notifications = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool isRefreshing = false;
  bool isDeleting = false;
  String? nextPageUrl;
  int currentPage = 1;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<RemoteMessage>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = Provider.of<NotificationStore>(context, listen: false);
      store.clear();
    });
    _loadNotifications();
    _scrollController.addListener(_onScroll);
    
    // Set up direct Firebase messaging listener for this page
    _messageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Logger.log('📱 Direct message received on notifications page: ${message.messageId}');
      if (mounted) {
        Logger.log('📱 Refreshing notifications due to new message');
        setState(() {
          isRefreshing = true;
        });
        _loadNotifications(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Cancel the message subscription when leaving the page
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    Logger.log('🔄 Loading notifications, refresh: $refresh, currentPage: $currentPage');
    
    if (refresh) {
      setState(() {
        isRefreshing = true;
        currentPage = 1;
        nextPageUrl = null;
      });
    }
    
    final result = await ApiService.fetchNotifications(page: currentPage);
    Logger.log('📨 API result: $result');
    
    setState(() {
      if (refresh) {
        notifications = (result['notifications'] as List).cast<NotificationItem>();
        isRefreshing = false;
        Logger.log('🔄 Refresh completed, notifications count: ${notifications.length}');
      } else {
        notifications.addAll((result['notifications'] as List).cast<NotificationItem>());
        isLoading = false;
        Logger.log('🔄 Initial load completed, notifications count: ${notifications.length}');
      }
      nextPageUrl = result['nextPageUrl'] as String?;
      isLoadingMore = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !isLoadingMore && nextPageUrl != null) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (isLoadingMore || nextPageUrl == null) return;
    setState(() {
      isLoadingMore = true;
      currentPage++;
    });
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5F2),
        body: Column(
          children: [
            // AppBar with back button and delete button
            CustomAppBar(
              showBackButton: true,
              onBackPressed: () => Get.back(),
              showNotificationButton: true,
              showDeleteNotificationsButton: true,
              onDeleteNotificationsPressed: () async {
                await showCustomDialog(
                  context: context,
                  title: 'تأكيد الحذف',
                  message: 'هل أنت متأكد أنك تريد حذف جميع الإشعارات؟',
                  okButtonText: 'حذف',
                  cancelButtonText: 'إلغاء',
                  onOkPressed: () async {
                    setState(() {
                      isDeleting = true;
                    });
                    
                    final success = await ApiService.deleteAllNotifications();
                    
                    if (success) {
                      // Reset notification count in store
                      final store = Provider.of<NotificationStore>(context, listen: false);
                      store.clear();
                      
                      setState(() {
                        notifications.clear();
                        isLoading = false;
                        isRefreshing = false;
                        isDeleting = false;
                      });
                      if (mounted) {
                        ToastHelper.showToast(context, 'تم حذف جميع الإشعارات بنجاح', isError: false);
                      }
                    } else {
                      setState(() {
                        isDeleting = false;
                      });
                      if (mounted) {
                        ToastHelper.showToast(context, 'فشل في حذف الإشعارات', isError: true);
                      }
                    }
                  },
                  isWarning: true,
                );
              },
            ),
            // Notifications list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  Logger.log('Pull to refresh triggered');
                  await _loadNotifications(refresh: true);
                  Logger.log('Pull to refresh completed');
                },
                child: (isLoading && !isRefreshing) || isDeleting
                    ? const Center(child: CustomSpinner(size: 50.0))
                    : notifications.isEmpty
                        ? SizedBox(
                            height: MediaQuery.of(context).size.height - 100, // Subtract AppBar height
                            child: _buildEmptyState(),
                          )
                        : _buildNotificationsList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 80), // Add top spacing
        Image.asset(
          'assets/images/empty_notifications.png',
          width: 120,
          height: 120,
        ),
        const SizedBox(height: 16),
        Text(
          'لا يوجد إشعارات',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF633e3d),
            fontFamily: 'Cairo',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'سترى الإشعارات هنا عندما تتلقى إشعارات',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontFamily: 'Cairo',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNotificationsList() {
    return ListView.separated(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: notifications.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFE4E4E7)),
      itemBuilder: (context, index) {
        if (index >= notifications.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: SizedBox()),
          );
        }
        final notification = notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    IconData icon;
    VoidCallback? onTap;
    
    Logger.log('Notification type: ${notification.type}, content: ${notification.content}');
    
    switch (notification.type.toLowerCase()) {
      case 'url':
        icon = Icons.link;
        if (notification.content.startsWith('http')) {
          onTap = () => _openUrl(notification.content);
          Logger.log('URL notification found, will open: ${notification.content}');
        } else {
          Logger.log('URL notification but content does not start with http: ${notification.content}');
        }
        break;
      case 'share':
        icon = Icons.trending_up;
        onTap = () => _openShare(notification.content);
        break;
      case 'apartment':
        icon = Icons.home_outlined;
        onTap = () => _openApartment(notification.content);
        break;
      default:
        icon = Icons.notifications;
        break;
    }
    
    return InkWell(
      onTap: onTap,
              child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFEAE2DB),
              child: Icon(icon, color: const Color(0xFF633e3d), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF633e3d),
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF633e3d),
                      fontFamily: 'Cairo',
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatDate(notification.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Format as dd/mm/yyyy
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ToastHelper.showToast(context, 'لا يمكن فتح الرابط', isError: true);
        }
      }
    } catch (e) {
      Logger.error('Error launching URL: $e');
      if (mounted) {
        ToastHelper.showToast(context, 'خطأ في فتح الرابط', isError: true);
      }
    }
  }

  void _openShare(String shareId) {
    try {
      final id = int.tryParse(shareId);
      if (id != null) {
        Get.to(() => PropertyDetailsPage(
          id: id,
          itemType: 'share',
        ));
      } else {
        Logger.error('Invalid share ID: $shareId');
        ToastHelper.showToast(context, 'خطأ في معرف المشاركة', isError: true);
      }
    } catch (e) {
      Logger.error('Error opening share: $e');
      ToastHelper.showToast(context, 'خطأ في فتح المشاركة', isError: true);
    }
  }

  void _openApartment(String apartmentId) {
    try {
      final id = int.tryParse(apartmentId);
      if (id != null) {
        Get.to(() => PropertyDetailsPage(
          id: id,
          itemType: 'apartment',
        ));
      } else {
        Logger.error('Invalid apartment ID: $apartmentId');
        ToastHelper.showToast(context, 'خطأ في معرف الشقة', isError: true);
      }
    } catch (e) {
      Logger.error('Error opening apartment: $e');
      ToastHelper.showToast(context, 'خطأ في فتح الشقة', isError: true);
    }
  }
} 