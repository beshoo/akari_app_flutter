import 'package:akari_app/pages/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phone_form_field/phone_form_field.dart';
import '../stores/auth_store.dart';
import 'otp_validation_page.dart';
import '../utils/toast_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Form controllers
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Form state
  String _countryCode = 'SY';
  String _phone = '';

  // Store instances
  late AuthStore _authStore;

  @override
  void initState() {
    super.initState();
    _authStore = Provider.of<AuthStore>(context, listen: false);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // Handle send OTP
  Future<void> _handleSendCode() async {
    // Hide keyboard when button is pressed
    FocusScope.of(context).unfocus();
    
    if (_phone.isEmpty) {
      ToastHelper.showToast(context, 'يرجى إدخال رقم الهاتف', isError: true);
      return;
    }

    final data = {
      'country_code': _countryCode,
      'phone': _phone,
    };

    final result = await _authStore.requestOtp(data);

    if (!mounted) return;

    if (result['success'] == true) {
      ToastHelper.showToast(context, result['message'] ?? 'تم إرسال الكود بنجاح',
          isError: false);

      // Navigate to OTP validation
      Navigator.pushNamed(
        context,
        '/otp_validation',
        arguments: {
          'phone': _phone,
          'countryCode': _countryCode,
          'parent': 'login',
        },
      );
    } else {
      ToastHelper.showToast(context, result['message'] ?? 'حدث خطأ ما',
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header with close button and logo
                      _buildHeader(),

                      // Title section
                      _buildTitle(),

                      // Form section
                      _buildForm(),
                    ],
                  ),
                ),
              ),

              // Bottom section with button
              _buildBottom(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Logo (RTL: right side)
          SizedBox(
            width: 96,
            height: 96,
            child: Image.asset('assets/images/icon.png'),
          ),

          const Spacer(),

          // Close button (RTL: left side)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFa47764)),
              color: Colors.transparent,
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Color(0xFFa47764)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'تسجيل الدخول',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              color: Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 8),
          const Text(
            'أدخل رقم هاتفك لتسجيل الدخول',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6b7280),
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Phone number input
            _buildPhoneInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: PhoneFormField(
            initialValue: const PhoneNumber(isoCode: IsoCode.SY, nsn: ''),
            decoration: InputDecoration(
              labelStyle: const TextStyle(fontFamily: 'Cairo'),
              hintStyle: const TextStyle(fontFamily: 'Cairo'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFa47764)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFa47764)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFa47764)),
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            countrySelectorNavigator: CountrySelectorNavigator.dialog(
              countries: IsoCode.values.where((iso) => iso.name != 'IL').toList(),
              searchBoxDecoration: const InputDecoration(
                filled: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Color(0xFFa47764)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Color(0xFFa47764)),
                ),
                suffixIcon: Icon(Icons.search),
                hintStyle: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
            onChanged: (phone) {
              setState(() {
                _phone = phone.nsn;
                _countryCode = phone.isoCode.name;
              });
            },
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
        if (_phone.isEmpty)
          const Positioned(
            right: 17,
            child: IgnorePointer(
              child: Text(
                'رقم الهاتف',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: Color(0xFF9ca3af),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottom() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Signup button
          Consumer<AuthStore>(
            builder: (context, authStore, child) {
              bool isEnabled =
                  _phone.isNotEmpty && !authStore.otpLoading;

              return SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: isEnabled ? _handleSendCode : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: isEnabled
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF633e3d),
                                Color(0xFF774b46),
                                Color(0xFF8d5e52),
                                Color(0xFFa47764),
                                Color(0xFFbda28c),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color: isEnabled
                          ? null
                          : const Color(0x99bda28c),
                    ),
                    child: Container(
                      height: 45,
                      alignment: Alignment.center,
                      child: authStore.otpLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'إرسال الكود',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Cairo',
                              ),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'جديد في عقاري؟ ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6b7280),
                  fontFamily: 'Cairo',
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/signup');
                },
                child: const Text(
                  'إنشاء حساب',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF633e3d),
                    fontFamily: 'Cairo',
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 