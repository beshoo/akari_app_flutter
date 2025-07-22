import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../stores/auth_store.dart';
import '../utils/logger.dart';
import '../utils/toast_helper.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    final authStore = Provider.of<AuthStore>(context, listen: false);
    final supportPhone = _cleanPhoneNumber(authStore.supportPhone);
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5F2),
        appBar: CustomAppBar(
          title: 'المساعدة والدعم',
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
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
              ],
            ),
          ),
        ),
      ),
    );
  }
} 