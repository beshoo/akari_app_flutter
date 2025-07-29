import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../stores/auth_store.dart';
import '../utils/logger.dart';
import '../utils/toast_helper.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  @override
  void initState() {
    super.initState();
    // Set the status bar to be transparent and overlay the content
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    // Reset the status bar when leaving the page
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }

  String _cleanPhoneNumber(String? number) {
    if (number == null) return '';
    return number.replaceAll(RegExp(r'[^\d+]'), '');
  }

  Future<void> _handleWhatsAppSupport(BuildContext context) async {
    final authStore = Provider.of<AuthStore>(context, listen: false);
    final supportPhone = _cleanPhoneNumber(authStore.supportPhone);
    Logger.log('Support phone for WhatsApp: $supportPhone');
    if (supportPhone.isNotEmpty) {
      final whatsappUrl = Uri.parse(
        'whatsapp://send?phone=$supportPhone&text=${Uri.encodeComponent('مرحبا، أحتاج المساعدة والدعم')}',
      );
      try {
        final supported = await canLaunchUrl(whatsappUrl);
        if (supported) {
          await launchUrl(whatsappUrl);
        } else {
          ToastHelper.showToast(context, 'تطبيق واتساب غير مثبت على هذا الجهاز', isError: true);
        }
      } catch (e) {
        Logger.error('Error opening WhatsApp', e);
        ToastHelper.showToast(context, 'حدث خطأ أثناء فتح واتساب', isError: true);
      }
    } else {
      ToastHelper.showToast(context, 'رقم الدعم غير متوفر', isError: true);
    }
  }

  Future<void> _handlePhoneSupport(BuildContext context) async {
    final authStore = Provider.of<AuthStore>(context, listen: false);
    final supportPhone = _cleanPhoneNumber(authStore.supportPhone);
    Logger.log('Support phone for call: $supportPhone');
    if (supportPhone.isNotEmpty) {
      final telUrl = Uri.parse('tel:$supportPhone');
      try {
        final supported = await canLaunchUrl(telUrl);
        if (supported) {
          await launchUrl(telUrl);
        } else {
          ToastHelper.showToast(context, 'لا يمكن إجراء المكالمة', isError: true);
        }
      } catch (e) {
        Logger.error('Error making phone call', e);
        ToastHelper.showToast(context, 'حدث خطأ أثناء إجراء المكالمة', isError: true);
      }
    } else {
      ToastHelper.showToast(context, 'رقم الدعم غير متوفر', isError: true);
    }
  }

  Future<void> _handleGoogleMapsLocation(BuildContext context) async {
    const String googleMapsUrl = 'https://www.google.com/maps/place/33%C2%B030\'19.8%22N+36%C2%B015\'35.1%22E/@33.5052254,36.2598391,19.13z/data=!4m4!3m3!8m2!3d33.505491!4d36.259739!5m1!1e1?entry=ttu&g_ep=EgoyMDI1MDcyMy4wIKXMDSoASAFQAw%3D%3D';
    
    // Try to open with Google Maps app first
    final googleMapsAppUrl = Uri.parse('comgooglemaps://?q=33.505491,36.259739');
    
    try {
      final mapsAppSupported = await canLaunchUrl(googleMapsAppUrl);
      if (mapsAppSupported) {
        Logger.log('Opening location in Google Maps app');
        await launchUrl(googleMapsAppUrl);
      } else {
        // Fallback to opening in browser
        Logger.log('Google Maps app not available, opening in browser');
        final webUrl = Uri.parse(googleMapsUrl);
        final webSupported = await canLaunchUrl(webUrl);
        if (webSupported) {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        } else {
          ToastHelper.showToast(context, 'لا يمكن فتح الخريطة', isError: true);
        }
      }
    } catch (e) {
      Logger.error('Error opening Google Maps', e);
      ToastHelper.showToast(context, 'حدث خطأ أثناء فتح الخريطة', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStore = Provider.of<AuthStore>(context, listen: false);
    final supportPhone = _cleanPhoneNumber(authStore.supportPhone);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: CustomAppBar(
        showLogo: true,
        showBackButton: true,
        showFavoritesButton: true,
        showHelpButton: true,
        showSearchButton: true,
        showNotificationButton: true,
        onlyText: false,
        onBackPressed: () => Navigator.of(context).pop(),
        titleStyle: TextStyle(
          fontSize: MediaQuery.of(context).size.width > 400 ? 22.0 : 20.0,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
          color: const Color(0xFF1A1A1A),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Image.asset(
              'assets/images/icons/support_2.png',
              height: 100,
              color: const Color(0xFFA47764),
            ),
            const SizedBox(height: 24),
            const Text(
              'المساعدة والدعم',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'نحن هنا للمساعدة إذا كان لديك سؤال, فريقنا موجود',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  CustomButton(
                    hasGradient: false,
                    title: 'واتساب',
                    onPressed: () => _handleWhatsAppSupport(context),
                    textColor: Colors.green.shade700,
                    borderColor: Colors.green.shade700,
                    height: 45,
                    borderRadius: 8,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    hasGradient: false,
                    title: 'اتصال هاتفي: $supportPhone+',
                    onPressed: () => _handlePhoneSupport(context),
                    textColor: Colors.blue.shade500,
                    borderColor: Colors.blue.shade500,
                    height: 45,
                    borderRadius: 8,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GestureDetector(
                onTap: () => _handleGoogleMapsLocation(context),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/management.png',
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'اضغط للوصول إلى موقعنا',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
} 