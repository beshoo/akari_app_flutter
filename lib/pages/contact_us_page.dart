import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../stores/auth_store.dart';
import '../utils/logger.dart';
import '../utils/toast_helper.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/custom_rich_text.dart';
import '../data/repositories/share_repository.dart';
import '../data/repositories/apartment_repository.dart';
import 'chat_page.dart';

class ContactUsPage extends StatefulWidget {
  final dynamic itemData;

  const ContactUsPage({super.key, required this.itemData});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final ShareRepository _shareRepository = ShareRepository();
  final ApartmentRepository _apartmentRepository = ApartmentRepository();
  
  // Local state to track the current item data
  dynamic _currentItemData;
  
  // Loading state for cancel button
  bool _isCancellingAppointment = false;
  
  // Loading state for creating appointment
  bool _isCreatingAppointment = false;

  @override
  void initState() {
    super.initState();
    _currentItemData = widget.itemData;
  }

  Future<void> _refreshItemData() async {
    if (_currentItemData == null) return;
    
    final itemId = _currentItemData.id;
    final postType = _currentItemData.postType ?? '';
    
    Logger.log('🔄 Refreshing item data for ID: $itemId, type: $postType');
    
    try {
      if (postType == 'share') {
        final refreshedData = await _shareRepository.fetchShareById(itemId);
        if (refreshedData != null && mounted) {
          setState(() {
            _currentItemData = refreshedData;
          });
          Logger.log('✅ Share data refreshed successfully');
        }
      } else {
        final refreshedData = await _apartmentRepository.fetchApartmentById(itemId);
        if (refreshedData != null && mounted) {
          setState(() {
            _currentItemData = refreshedData;
          });
          Logger.log('✅ Apartment data refreshed successfully');
        }
      }
    } catch (e) {
      Logger.error('❌ Error refreshing item data: $e');
    }
  }

  String _cleanPhoneNumber(String? number) {
    if (number == null) return '';
    return number.replaceAll(RegExp(r'[^\d+]'), '');
  }

  void _showIntentionDialog(BuildContext context, VoidCallback proceedWithAction) {
    showIntentionDialog(
      context: context,
      title: 'ما ذا تريد أن تفعل؟',
      onBuyPressed: () => _handleIntentionSelection(context, 'buy', proceedWithAction),
      onSellPressed: () => _handleIntentionSelection(context, 'sell', proceedWithAction),
    );
  }

  void _proceedWithAppointment(BuildContext context, String intention) async {
    final itemId = _currentItemData?.id;
    final postType = _currentItemData?.postType ?? '';
    
    Logger.log('🚀 _proceedWithAppointment called!');
    Logger.log('🚀 Item ID: $itemId');
    Logger.log('🚀 Post Type: $postType');
    Logger.log('🚀 Intention: $intention');
    Logger.log('🚀 ItemData: ${_currentItemData?.toJson()}');
    
    if (itemId == null) {
      Logger.log('❌ Item ID is null!');
      ToastHelper.showToast(context, 'خطأ في معرف العنصر', isError: true);
      return;
    }

    Logger.log('📅 Creating $intention request for $postType ID: $itemId');
    Logger.log('📅 About to call API...');

    // Set loading state
    setState(() {
      _isCreatingAppointment = true;
    });

    try {
      Map<String, dynamic> result;
      
      if (postType == 'share') {
        if (intention == 'buy') {
          Logger.log('📞 Calling share createBuyRequest...');
          result = await _shareRepository.createBuyRequest(itemId);
        } else {
          Logger.log('📞 Calling share createSellRequest...');
          result = await _shareRepository.createSellRequest(itemId);
        }
      } else {
        // Apartment
        if (intention == 'buy') {
          Logger.log('📞 Calling apartment createBuyRequest...');
          result = await _apartmentRepository.createBuyRequest(itemId);
        } else {
          Logger.log('📞 Calling apartment createSellRequest...');
          result = await _apartmentRepository.createSellRequest(itemId);
        }
      }

      Logger.log('📅 API Response: $result');

      if (mounted) {
        // Reset loading state
        setState(() {
          _isCreatingAppointment = false;
        });

        if (result['success'] == true) {
          Logger.log('✅ Success! Showing success toast');
          ToastHelper.showToast(context, 'تم ترتيب الموعد بنجاح', isError: false);
          // Refresh data to get the updated orderable information
          await _refreshItemData();
        } else {
          Logger.log('❌ Failed! Showing error toast');
          ToastHelper.showToast(context, result['message'] ?? 'فشل في ترتيب الموعد', isError: true);
        }
      }
    } catch (e) {
      Logger.error('❌ Exception in _proceedWithAppointment: $e');
      if (mounted) {
        // Reset loading state
        setState(() {
          _isCreatingAppointment = false;
        });
        ToastHelper.showToast(context, 'حدث خطأ أثناء ترتيب الموعد', isError: true);
      }
    }
  }

  void _handleIntentionSelection(BuildContext context, String intention, VoidCallback proceedWithAction) {
    final String? typeOfContact = _currentItemData?.transactionType;
    
    Logger.log('🎯 Intention selected: $intention');
    Logger.log('🎯 Transaction type from itemData: $typeOfContact');
    
    if (intention == 'buy') {
      if (typeOfContact == 'sell') {
        Logger.log('✅ Correct match: User wants to buy from a sell post');
        proceedWithAction();
      } else {
        Logger.log('❌ Wrong match: User wants to buy from a buy post - showing error');
        _showErrorDialog(context, 'لا يمكنك الشراء من هذا الإعلان لأنه طلب شراء.');
      }
    } else if (intention == 'sell') {
      if (typeOfContact == 'buy') {
        Logger.log('✅ Correct match: User wants to sell to a buy request');
        proceedWithAction();
      } else {
        Logger.log('❌ Wrong match: User wants to sell to a sell post - showing error');
        _showErrorDialog(context, 'لا يمكنك البيع لهذا الإعلان لأنه بالفعل إعلان بيع.');
      }
    } else {
      Logger.log('⚠️ Unknown intention: $intention');
    }
  }

  void _showIntentionDialogForDateArrangement(BuildContext context) {
    showIntentionDialog(
      context: context,
      title: 'ما ذا تريد أن تفعل؟',
      onBuyPressed: () => _handleDateArrangementIntention(context, 'buy'),
      onSellPressed: () => _handleDateArrangementIntention(context, 'sell'),
    );
  }

  void _handleDateArrangementIntention(BuildContext context, String intention) {
    final String? typeOfContact = _currentItemData?.transactionType;
    final String postType = _currentItemData?.postType ?? '';
    
    Logger.log('📅 Date arrangement intention: $intention');
    Logger.log('📅 Transaction type: $typeOfContact');
    Logger.log('📅 Post type: $postType');
    
    if (intention == 'buy') {
      if (typeOfContact == 'sell') {
        Logger.log('✅ Correct match: User wants to buy from a sell post');
        if (postType == 'share' || postType == 'apartment') {
          _proceedWithAppointment(context, 'buy');
        } else {
          _proceedWithDateArrangement(context);
        }
      } else {
        Logger.log('❌ Wrong match: User wants to buy from a buy post');
        _showErrorDialog(context, 'لا يمكنك الشراء من هذا الإعلان لأنه طلب شراء.');
      }
    } else if (intention == 'sell') {
      if (typeOfContact == 'buy') {
        Logger.log('✅ Correct match: User wants to sell to a buy request');
        if (postType == 'share' || postType == 'apartment') {
          _proceedWithAppointment(context, 'sell');
        } else {
          _proceedWithDateArrangement(context);
        }
      } else {
        Logger.log('❌ Wrong match: User wants to sell to a sell post');
        _showErrorDialog(context, 'لا يمكنك البيع لهذا الإعلان لأنه بالفعل إعلان بيع.');
      }
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    Logger.log('🚨 _showErrorDialog called with message: $message');
    Logger.log('🚨 Checking mounted status immediately');
    Logger.log('🚨 mounted: $mounted, context.mounted: ${context.mounted}');
    
    // Check if widget is still mounted before showing dialog
    if (mounted && context.mounted) {
      Logger.log('🚨 About to call showCustomDialog immediately');
      showCustomDialog(
        context: context,
        title: 'خطأ',
        message: message,
        isWarning: true,
      );
      Logger.log('🚨 showCustomDialog called');
    } else {
      Logger.log('🚨 Widget not mounted, skipping dialog');
    }
  }

  void _handlePhonePress(BuildContext context) async {
    Logger.log('📞 Phone button pressed');
    _showIntentionDialog(context, () => _proceedWithPhoneCall(context));
  }

  void _proceedWithPhoneCall(BuildContext context) async {
    final authStore = Provider.of<AuthStore>(context, listen: false);
    final supportPhone = _cleanPhoneNumber(authStore.supportPhone);
    
    Logger.log('📞 Support phone from auth store: ${authStore.supportPhone}');
    Logger.log('📞 Cleaned support phone: $supportPhone');
    
    if (supportPhone.isNotEmpty) {
      final uri = Uri.parse('tel:$supportPhone');
      Logger.log('📞 Attempting to launch: $uri');
      
      try {
        final canLaunch = await canLaunchUrl(uri);
        Logger.log('📞 Can launch URL: $canLaunch');
        
        if (canLaunch) {
          final launched = await launchUrl(uri);
          Logger.log('📞 Launch result: $launched');
        } else {
          Logger.log('📞 Cannot launch phone URL');
          if (mounted) {
            ToastHelper.showToast(context, 'لا يمكن إجراء المكالمة', isError: true);
          }
        }
      } catch (e) {
        Logger.log('📞 Error launching phone: $e');
        if (mounted) {
          ToastHelper.showToast(context, 'حدث خطأ أثناء إجراء المكالمة', isError: true);
        }
      }
    } else {
      Logger.log('📞 No support phone available');
      if (mounted) {
        ToastHelper.showToast(context, 'رقم الدعم غير متوفر', isError: true);
      }
    }
  }

  void _handleWhatsappPress(BuildContext context) async {
    Logger.log('💬 WhatsApp button pressed');
    _showIntentionDialog(context, () => _proceedWithWhatsApp(context));
  }

  void _proceedWithWhatsApp(BuildContext context) async {
    final authStore = Provider.of<AuthStore>(context, listen: false);
    final cleanedPhoneNumber = _cleanPhoneNumber(authStore.supportPhone);
    
    Logger.log('💬 Support phone from auth store: ${authStore.supportPhone}');
    Logger.log('💬 Cleaned phone number: $cleanedPhoneNumber');
    
    if (cleanedPhoneNumber.isNotEmpty) {
      // Access question_message from the details response (apartment or share) - this is the clean WhatsApp message
      final question = _currentItemData.questionMessage;
      final defaultMessage = 'أود الاستفسار عن العقار المعروض';
      final message = question ?? defaultMessage;
      final whatsappUrl = Uri.parse('whatsapp://send?phone=$cleanedPhoneNumber&text=${Uri.encodeComponent(message)}');
      
      Logger.log('💬 Question message from itemData: $question');
      Logger.log('💬 Final message: $message');
      Logger.log('💬 WhatsApp URL: $whatsappUrl');
      
      try {
        final supported = await canLaunchUrl(whatsappUrl);
        Logger.log('💬 WhatsApp URL supported: $supported');
        
        if (supported) {
          final launched = await launchUrl(whatsappUrl);
          Logger.log('💬 WhatsApp launch result: $launched');
        } else {
          Logger.log('💬 WhatsApp not supported');
          if (mounted) {
            ToastHelper.showToast(context, 'تطبيق واتساب غير مثبت على هذا الجهاز', isError: true);
          }
        }
      } catch (error) {
        Logger.log('💬 Error launching WhatsApp: $error');
        if (mounted) {
          ToastHelper.showToast(context, 'حدث خطأ أثناء فتح واتساب', isError: true);
        }
      }
    } else {
      Logger.log('💬 No phone number available');
      if (mounted) {
        ToastHelper.showToast(context, 'رقم الهاتف غير متوفر', isError: true);
      }
    }
  }

  void _handleAIChatPress(BuildContext context) {
    // Navigate to chat page
    Navigator.of(context).push(
      MaterialPageRoute(
                        builder: (context) => const ChatPage(),
      ),
    );
  }

  void _handleDatePress(BuildContext context) {
    Logger.log('📅 Date arrangement button pressed');
    _showIntentionDialogForDateArrangement(context);
  }

  void _proceedWithDateArrangement(BuildContext context) {
    final postType = _currentItemData?.postType ?? '';
    
    Logger.log('📅 Post type: $postType');
    
    if (postType == 'share' || postType == 'apartment') {
      // For shares and apartments, show success message - actual API call will be made after intention selection
      ToastHelper.showToast(context, 'سيتم التواصل معك لترتيب الموعد', isError: false);
    } else {
      // For other types, keep existing logic
      ToastHelper.showToast(context, 'سيتم التواصل معك لترتيب الموعد', isError: false);
    }
  }

  void _handleCancelAppointment(BuildContext context) async {
    final orderable = _currentItemData?.orderable;
    final orderId = orderable?['id'];
    
    if (orderId == null) {
      ToastHelper.showToast(context, 'خطأ في معرف الموعد', isError: true);
      return;
    }

    // Show confirmation dialog
    showCustomDialog(
      context: context,
      title: 'تأكيد الإلغاء',
      message: 'هل أنت متأكد من رغبتك في إلغاء الموعد؟',
      okButtonText: 'نعم، إلغاء',
      cancelButtonText: 'لا',
      isWarning: true,
      onOkPressed: () => _confirmCancelAppointment(context, orderId),
    );
  }

  void _confirmCancelAppointment(BuildContext context, int orderId) async {
    Logger.log('🚀 _confirmCancelAppointment called!');
    Logger.log('🚀 Order ID: $orderId');
    Logger.log('📅 Cancelling appointment with order ID: $orderId');
    Logger.log('📅 About to call cancelOrder API...');

    // Set loading state
    setState(() {
      _isCancellingAppointment = true;
    });

    try {
      Logger.log('📞 Calling cancelOrder...');
      final postType = _currentItemData?.postType ?? '';
      
      Map<String, dynamic> result;
      if (postType == 'share') {
        result = await _shareRepository.cancelOrder(orderId);
      } else {
        result = await _apartmentRepository.cancelOrder(orderId);
      }
      
      Logger.log('📅 Cancel API Response: $result');

      if (mounted) {
        // Reset loading state
        setState(() {
          _isCancellingAppointment = false;
        });

        if (result['success'] == true) {
          Logger.log('✅ Cancel Success! Showing success toast');
          ToastHelper.showToast(context, 'تم إلغاء الموعد بنجاح', isError: false);
          // Refresh data to remove the orderable information and update UI
          await _refreshItemData();
        } else {
          Logger.log('❌ Cancel Failed! Showing error toast');
          ToastHelper.showToast(context, result['message'] ?? 'فشل في إلغاء الموعد', isError: true);
        }
      }
    } catch (e) {
      Logger.error('❌ Exception in _confirmCancelAppointment: $e');
      if (mounted) {
        // Reset loading state
        setState(() {
          _isCancellingAppointment = false;
        });
        ToastHelper.showToast(context, 'حدث خطأ أثناء إلغاء الموعد', isError: true);
      }
    }
  }

  Widget _buildDateArrangementOption(BuildContext context) {
    final orderable = _currentItemData?.orderable;
    final hasAppointment = orderable != null;
    
    return Column(
      children: [
        _buildContactOption(
          context: context,
          iconPath: 'assets/images/icons/date.png',
          title: 'ترتيب موعد',
          subtitle: 'أرسل إعلانك إلينا وسيقوم فريق عقاري بالتواصل معك لتحديد الموعد المناسب وترتيب كافة التفاصيل.',
          onTap: (hasAppointment || _isCreatingAppointment) ? null : () => _handleDatePress(context),
          isDisabled: hasAppointment,
          isLoading: _isCreatingAppointment,
        ),
        if (hasAppointment) ...[
          const SizedBox(height: 16),
          _buildCancelAppointmentButton(context),
        ],
      ],
    );
  }

  Widget _buildCancelAppointmentButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: _isCancellingAppointment ? null : () => _handleCancelAppointment(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isCancellingAppointment ? Colors.grey.shade400 : Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isCancellingAppointment
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'جاري الإلغاء...',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : const Text(
                'إلغاء الموعد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print auth store data
    final authStore = Provider.of<AuthStore>(context, listen: false);
    Logger.log('🔍 DEBUG - AuthStore data:');
    Logger.log('🔍 Support Phone: ${authStore.supportPhone}');
    Logger.log('🔍 User ID: ${authStore.userId}');
    Logger.log('🔍 User Name: ${authStore.userName}');
    Logger.log('🔍 Is Authenticated: ${authStore.isAuthenticated}');
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: CustomAppBar(
        title: 'إختر طريقة التواصل',
        showBackButton: true,
        showLogo: false,
        onlyText: true,
        onBackPressed: () => Navigator.of(context).pop(),
        titleStyle: TextStyle(
          fontSize: MediaQuery.of(context).size.width > 400 ? 22.0 : 20.0,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
          color: const Color(0xFF1A1A1A),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
                             // Note about commission
               Container(
                 width: double.infinity,
                 padding: const EdgeInsets.all(16),
                 margin: const EdgeInsets.only(bottom: 20),
                 decoration: BoxDecoration(
                   color: const Color(0xFFF7F5F2),
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(
                     color: const Color(0xFF8B4513),
                     width: 1,
                   ),
                   boxShadow: [
                     BoxShadow(
                       color: Colors.black.withValues(alpha: 0.1),
                       offset: const Offset(0, 2),
                       blurRadius: 4,
                       spreadRadius: 0,
                     ),
                   ],
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       children: [
                         Icon(
                           Icons.info_outline,
                           color: const Color(0xFF8B4513),
                           size: 20,
                         ),
                         const SizedBox(width: 8),
                         const Text(
                           'ملاحظة:',
                           style: TextStyle(
                             fontFamily: 'Cairo',
                             fontSize: 16,
                             fontWeight: FontWeight.bold,
                             color: Color(0xFF8B4513),
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 8),
                     CustomRichText(
                       text: 'عند إتمام أي صفقة بيع أو شراء عبر تطبيق عقاري، سوف يتم احتساب عمولة بنسبة <b>2٪</b> من البائع و <b>1٪</b> من المشتري.',
                       textAlign: TextAlign.justify,
                       fontFamily: 'Cairo',
                       fontSize: 14,
                       height: 2,
                       baseStyle: const TextStyle(
                         color: Color(0xFF1A1A1A),
                       ),
                     ),
                   ],
                 ),
               ),
              // Debug info (remove in production)
/*               Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.yellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'DEBUG: Support Phone: ${authStore.supportPhone ?? "NULL"}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'Cairo'),
                ),
              ), */
              _buildContactOption(
                context: context,
                iconPath: 'assets/images/icons/phone.png',
                title: 'عن طريق الهاتف',
                subtitle: 'يمكنك الاتصال المباشر بفريق عقاري للحصول على المساعدة الفورية.',
                onTap: () => _handlePhonePress(context),
              ),
              const Divider(height: 30, thickness: 1),
              _buildContactOption(
                context: context,
                iconPath: 'assets/images/icons/whats_app.png',
                title: 'عن طريق الواتساب',
                subtitle: 'تواصل معنا بسهولة إما عن طريق الدردشة النصية أو إجراء مكالمة صوتية.',
                onTap: () => _handleWhatsappPress(context),
              ),
              const Divider(height: 30, thickness: 1),
              _buildContactOption(
                context: context,
                iconPath: 'assets/images/icons/support_2.png',
                title: 'عن طريق الدردشة مع الذكاء الاصطناعي',
                subtitle:
                    'احصل على إجابات فورية ومساعدة ذكية حول استفساراتك العقارية من خلال مساعدنا الذكي المتخصص.',
                onTap: () => _handleAIChatPress(context),
              ),
              const Divider(height: 30, thickness: 1),
              _buildDateArrangementOption(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactOption({
    required BuildContext context,
    required String iconPath,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isDisabled = false,
    bool isLoading = false,
  }) {
    final shouldDisableOption = isDisabled || isLoading;
    
    return Opacity(
      opacity: shouldDisableOption ? 0.5 : 1.0,
      child: InkWell(
        onTap: shouldDisableOption ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: shouldDisableOption ? const Color(0xFFCCCCCC) : const Color(0xFFEAEAEA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            shouldDisableOption ? const Color(0xFF999999) : const Color(0xFF1f2937),
                          ),
                        ),
                      )
                    : Image.asset(
                        iconPath,
                        width: 28,
                        height: 28,
                        color: shouldDisableOption ? const Color(0xFF999999) : const Color(0xFF1f2937),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoading ? 'جاري ترتيب الموعد...' : title,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: shouldDisableOption ? const Color(0xFF999999) : const Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: shouldDisableOption ? const Color(0xFF999999) : const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 