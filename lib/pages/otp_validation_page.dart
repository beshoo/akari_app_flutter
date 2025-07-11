import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../stores/auth_store.dart';
import '../utils/toast_helper.dart';
import '../services/firebase_messaging_service.dart';

class OtpValidationPage extends StatefulWidget {
  final String phone;
  final String countryCode;
  final String parent;
  
  const OtpValidationPage({
    super.key,
    required this.phone,
    required this.countryCode,
    required this.parent,
  });

  @override
  OtpValidationPageState createState() => OtpValidationPageState();
}

class OtpValidationPageState extends State<OtpValidationPage> {
  // OTP controllers
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  
  // State variables
  String _otp = '';
  bool _isResending = false;
  int _resendTimer = 60;
  bool _isAutofilling = false;
  int _currentIndex = 0; // Track current input position for number pad
  
  // Country code to dial code mapping
  String _getDialCode(String countryCode) {
    final Map<String, String> countryDialCodes = {

      'AD': '+376', 'AE': '+971', 'AF': '+93', 'AG': '+1', 'AI': '+1',
      'AL': '+355', 'AM': '+374', 'AO': '+244', 'AQ': '+672', 'AR': '+54',
      'AS': '+1', 'AT': '+43', 'AU': '+61', 'AW': '+297', 'AX': '+358',
      'AZ': '+994', 'BA': '+387', 'BB': '+1', 'BD': '+880', 'BE': '+32',
      'BF': '+226', 'BG': '+359', 'BH': '+973', 'BI': '+257', 'BJ': '+229',
      'BL': '+590', 'BM': '+1', 'BN': '+673', 'BO': '+591', 'BQ': '+599',
      'BR': '+55', 'BS': '+1', 'BT': '+975', 'BV': '+47', 'BW': '+267',
      'BY': '+375', 'BZ': '+501', 'CA': '+1', 'CC': '+61', 'CD': '+243',
      'CF': '+236', 'CG': '+242', 'CH': '+41', 'CI': '+225', 'CK': '+682',
      'CL': '+56', 'CM': '+237', 'CN': '+86', 'CO': '+57', 'CR': '+506',
      'CU': '+53', 'CV': '+238', 'CW': '+599', 'CX': '+61', 'CY': '+357',
      'CZ': '+420', 'DE': '+49', 'DJ': '+253', 'DK': '+45', 'DM': '+1',
      'DO': '+1', 'DZ': '+213', 'EC': '+593', 'EE': '+372', 'EG': '+20',
      'EH': '+212', 'ER': '+291', 'ES': '+34', 'ET': '+251', 'FI': '+358',
      'FJ': '+679', 'FK': '+500', 'FM': '+691', 'FO': '+298', 'FR': '+33',
      'GA': '+241', 'GB': '+44', 'GD': '+1', 'GE': '+995', 'GF': '+594',
      'GG': '+44', 'GH': '+233', 'GI': '+350', 'GL': '+299', 'GM': '+220',
      'GN': '+224', 'GP': '+590', 'GQ': '+240', 'GR': '+30', 'GS': '+500',
      'GT': '+502', 'GU': '+1', 'GW': '+245', 'GY': '+592', 'HK': '+852',
      'HM': '+672', 'HN': '+504', 'HR': '+385', 'HT': '+509', 'HU': '+36',
      'ID': '+62', 'IE': '+353', 'IL': '+972', 'IM': '+44', 'IN': '+91',
      'IO': '+246', 'IQ': '+964', 'IR': '+98', 'IS': '+354', 'IT': '+39',
      'JE': '+44', 'JM': '+1', 'JO': '+962', 'JP': '+81', 'KE': '+254',
      'KG': '+996', 'KH': '+855', 'KI': '+686', 'KM': '+269', 'KN': '+1',
      'KP': '+850', 'KR': '+82', 'KW': '+965', 'KY': '+1', 'KZ': '+7',
      'LA': '+856', 'LB': '+961', 'LC': '+1', 'LI': '+423', 'LK': '+94',
      'LR': '+231', 'LS': '+266', 'LT': '+370', 'LU': '+352', 'LV': '+371',
      'LY': '+218', 'MA': '+212', 'MC': '+377', 'MD': '+373', 'ME': '+382',
      'MF': '+590', 'MG': '+261', 'MH': '+692', 'MK': '+389', 'ML': '+223',
      'MM': '+95', 'MN': '+976', 'MO': '+853', 'MP': '+1', 'MQ': '+596',
      'MR': '+222', 'MS': '+1', 'MT': '+356', 'MU': '+230', 'MV': '+960',
      'MW': '+265', 'MX': '+52', 'MY': '+60', 'MZ': '+258', 'NA': '+264',
      'NC': '+687', 'NE': '+227', 'NF': '+672', 'NG': '+234', 'NI': '+505',
      'NL': '+31', 'NO': '+47', 'NP': '+977', 'NR': '+674', 'NU': '+683',
      'NZ': '+64', 'OM': '+968', 'PA': '+507', 'PE': '+51', 'PF': '+689',
      'PG': '+675', 'PH': '+63', 'PK': '+92', 'PL': '+48', 'PM': '+508',
      'PN': '+870', 'PR': '+1', 'PS': '+970', 'PT': '+351', 'PW': '+680',
      'PY': '+595', 'QA': '+974', 'RE': '+262', 'RO': '+40', 'RS': '+381',
      'RU': '+7', 'RW': '+250', 'SA': '+966', 'SB': '+677', 'SC': '+248',
      'SD': '+249', 'SE': '+46', 'SG': '+65', 'SH': '+290', 'SI': '+386',
      'SJ': '+47', 'SK': '+421', 'SL': '+232', 'SM': '+378', 'SN': '+221',
      'SO': '+252', 'SR': '+597', 'SS': '+211', 'ST': '+239', 'SV': '+503',
      'SX': '+1', 'SY': '+963', 'SZ': '+268', 'TC': '+1', 'TD': '+235',
      'TF': '+262', 'TG': '+228', 'TH': '+66', 'TJ': '+992', 'TK': '+690',
      'TL': '+670', 'TM': '+993', 'TN': '+216', 'TO': '+676', 'TR': '+90',
      'TT': '+1', 'TV': '+688', 'TW': '+886', 'TZ': '+255', 'UA': '+380',
      'UG': '+256', 'UM': '+1', 'US': '+1', 'UY': '+598', 'UZ': '+998',
      'VA': '+379', 'VC': '+1', 'VE': '+58', 'VG': '+1', 'VI': '+1',
      'VN': '+84', 'VU': '+678', 'WF': '+681', 'WS': '+685', 'YE': '+967',
      'YT': '+262', 'ZA': '+27', 'ZM': '+260', 'ZW': '+263',
      
    };
    
    return countryDialCodes[countryCode] ?? '+$countryCode';
  }
  
  // Format phone number for better readability
  String _formatPhoneNumber(String phoneNumber) {
    // Remove any existing spaces or formatting
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    
    // Format based on length
    if (cleanNumber.length >= 9) {
      // For numbers 9+ digits, format as: XXX XXX XXX
      if (cleanNumber.length == 9) {
        return '${cleanNumber.substring(0, 3)} ${cleanNumber.substring(3, 6)} ${cleanNumber.substring(6)}';
      } else if (cleanNumber.length == 10) {
        return '${cleanNumber.substring(0, 3)} ${cleanNumber.substring(3, 6)} ${cleanNumber.substring(6)}';
      } else if (cleanNumber.length == 11) {
        return '${cleanNumber.substring(0, 3)} ${cleanNumber.substring(3, 6)} ${cleanNumber.substring(6)}';
      } else {
        // For longer numbers, format as: XXX XXX XXXX
        return '${cleanNumber.substring(0, 3)} ${cleanNumber.substring(3, 6)} ${cleanNumber.substring(6)}';
      }
    } else if (cleanNumber.length >= 6) {
      // For shorter numbers, format as: XXX XXX
      return '${cleanNumber.substring(0, 3)} ${cleanNumber.substring(3)}';
    } else {
      // Return as is if too short
      return cleanNumber;
    }
  }
  
  @override
  void initState() {
    super.initState();
    _startResendTimer();
    for (var i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          _onFocus(i);
        }
      });
    }
  }
  
  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
  
  void _startResendTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (_resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
        _startResendTimer();
      }
    });
  }
  
  void _onOtpChanged(String value, int index) {
    if (_isAutofilling) return;

    if (value.length == 6 && int.tryParse(value) != null) {
      _handlePastedOtp(value);
      return;
    }

    // If more than one character is entered manually or pasted (and it's not a 6-digit OTP),
    // we take the first character. The subsequent `onChanged` call will handle focus change.
    if (value.length > 1) {
      _otpControllers[index].text = value[0];
      // Set selection to the end of the text
      _otpControllers[index].selection = TextSelection.fromPosition(
          TextPosition(offset: _otpControllers[index].text.length));
      return;
    }

    // Update current index based on input
    _currentIndex = _otpControllers.indexWhere((controller) => controller.text.isEmpty);
    if (_currentIndex == -1) _currentIndex = 6;

    setState(() {
      _otp = _otpControllers.map((controller) => controller.text).join();
    });
    
    // Check if OTP is complete (6 digits)
    if (_otp.length == 6) {
      // Hide keyboard
      FocusScope.of(context).unfocus();
      // Auto submit with a small delay for better UX
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _loginWithOtp();
        }
      });
      return;
    }
    
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    }
    
    if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }
  
  void _handlePastedOtp(String pastedOtp) {
    _isAutofilling = true;
    for (int i = 0; i < 6; i++) {
      _otpControllers[i].text = pastedOtp[i];
    }
    _isAutofilling = false;

    setState(() {
      _otp = pastedOtp;
    });

    FocusScope.of(context).unfocus();
    // Add a small delay for the UI to update
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _loginWithOtp();
      }
    });
  }
  
  void _onFocus(int index) {
    // Find the first empty text field
    int firstEmptyIndex = _otpControllers.indexWhere((c) => c.text.isEmpty);

    // If there is an empty field and the user focuses on a different field,
    // move the focus to the first empty field and show a message.
    if (firstEmptyIndex != -1 && index != firstEmptyIndex) {
      FocusScope.of(context).requestFocus(_focusNodes[firstEmptyIndex]);
      ToastHelper.showToast(context, 'يرجى البدء في إدخال الرمز من اليسار',
          isError: true);
    }
  }
  
  Future<void> _loginWithOtp() async {
    if (_otp.length != 6) {
      ToastHelper.showToast(context, 'يرجى إدخال رمز التحقق كاملاً',
          isError: true);
      return;
    }
    
    final authStore = Provider.of<AuthStore>(context, listen: false);
    
    final verifyData = {
      'phone': widget.phone,
      'otp_number': _otp,
      'country_code': widget.countryCode,
      'firebase': FirebaseMessagingService.instance.fcmToken ?? '',
    };
    
    final result = await authStore.loginWithOtp(verifyData);
    
    if (!mounted) return;
    
    if (result['success'] == true) {
      ToastHelper.showToast(context, 'تم التحقق بنجاح', isError: false);
      
      // Navigate to home page or dashboard
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ToastHelper.showToast(
          context, result['message'] ?? 'فشل في التحقق من الرمز',
          isError: true);
    }
  }
  
  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
    });
    
    final authStore = Provider.of<AuthStore>(context, listen: false);
    
    final otpData = {
      'country_code': widget.countryCode,
      'phone': widget.phone,
      'parent': widget.parent,
    };
    
    final result = await authStore.requestOtp(otpData);
    
    if (!mounted) return;
    
    if (result['success'] == true) {
      ToastHelper.showToast(context, 'تم إرسال رمز التحقق بنجاح',
          isError: false);
      setState(() {
        _resendTimer = 60;
      });
      _startResendTimer();
    } else {
      ToastHelper.showToast(
          context, result['message'] ?? 'فشل في إرسال رمز التحقق',
          isError: true);
    }
    
    setState(() {
      _isResending = false;
    });
  }
  
  void _onNumberPadTap(String number) {
    if (_currentIndex < 6) {
      _otpControllers[_currentIndex].text = number;
      setState(() {
        _otp = _otpControllers.map((controller) => controller.text).join();
        _currentIndex++;
      });
      
      // Check if OTP is complete (6 digits)
      if (_otp.length == 6) {
        // Hide keyboard
        FocusScope.of(context).unfocus();
        // Auto submit with a small delay for better UX
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _loginWithOtp();
          }
        });
      }
    }
  }
  
  void _onBackspaceTap() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _otpControllers[_currentIndex].text = '';
      setState(() {
        _otp = _otpControllers.map((controller) => controller.text).join();
      });
    }
  }
  
  void _onClearAll() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    setState(() {
      _otp = '';
      _currentIndex = 0;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  
                  SizedBox(height: 24),
                  
                  // Title and description
                  _buildTitle(),
                  
                  SizedBox(height: 24),
                  
                  // OTP input
                  _buildOtpInput(),
                  
                  SizedBox(height: 20),
                  
                  // Number pad
                  _buildNumberPad(),
                  
                  SizedBox(height: 20),
                  
                  // Verify button
                  _buildVerifyButton(),
                  
                  SizedBox(height: 16),
                  
                  // Resend OTP
                  _buildResendButton(),
                  
                  SizedBox(height: 16),
                  
                  // Footer
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Image.asset('assets/images/icon.png'),
        ),
        Spacer(),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Color(0xFFa47764)),
            color: Colors.transparent,
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFFa47764)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'تحقق من رقم الهاتف',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Text(
          'لقد أرسلنا رمز التحقق إلى',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6b7280),
            fontFamily: 'Cairo',
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            '${_getDialCode(widget.countryCode)} ${_formatPhoneNumber(widget.phone)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF633e3d),
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
  
  Widget _buildOtpInput() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (index) {
          return Container(
            width: 45,
            height: 55,
            decoration: BoxDecoration(
              border: Border.all(
                color: _otpControllers[index].text.isNotEmpty 
                  ? Color(0xFFa47764)
                  : (index == 0 && _otp.isEmpty) 
                    ? Color(0xFFa47764) 
                    : Color(0xFFd1d5db),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _otpControllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) => _onOtpChanged(value, index),
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildVerifyButton() {
    return Consumer<AuthStore>(
      builder: (context, authStore, child) {
        return Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                Color(0xFF633e3d),
                Color(0xFF774b46),
                Color(0xFF8d5e52),
                Color(0xFFa47764),
                Color(0xFFbda28c),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: ElevatedButton(
            onPressed: (_otp.length == 6 && !authStore.otpLoading) ? _loginWithOtp : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey.withAlpha(77),
            ),
            child: authStore.otpLoading
              ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : Text(
                  'تحقق',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                ),
          ),
        );
      },
    );
  }
  
  Widget _buildResendButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'لم تستلم الرمز؟ ',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6b7280),
            fontFamily: 'Cairo',
          ),
        ),
        if (_resendTimer > 0)
          Text(
            'إعادة الإرسال خلال ($_resendTimer)',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6b7280),
              fontFamily: 'Cairo',
            ),
          )
        else
          GestureDetector(
            onTap: _isResending ? null : _resendOtp,
            child: Text(
              _isResending ? 'جاري الإرسال...' : 'إعادة إرسال',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF633e3d),
                fontFamily: 'Cairo',
                decoration: TextDecoration.underline,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildFooter() {
    return Text(
      'يرجى إدخال الرمز المرسل إليك خلال الـ 10 دقائق القادمة',
      style: TextStyle(
        fontSize: 14,
        color: Color(0xFF6b7280),
        fontFamily: 'Cairo',
      ),
      textAlign: TextAlign.center,
    );
  }
  
  Widget _buildNumberPad() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Numbers 1-3 (RTL: 3-2-1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('3'),
              _buildNumberButton('2'),
              _buildNumberButton('1'),
            ],
          ),
          SizedBox(height: 12),
          // Numbers 4-6 (RTL: 6-5-4)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('6'),
              _buildNumberButton('5'),
              _buildNumberButton('4'),
            ],
          ),
          SizedBox(height: 12),
          // Numbers 7-9 (RTL: 9-8-7)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('9'),
              _buildNumberButton('8'),
              _buildNumberButton('7'),
            ],
          ),
          SizedBox(height: 12),
          // Backspace, 0, Clear (RTL arrangement)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.backspace_outlined,
                onTap: _onBackspaceTap,
                tooltip: 'مسح',
              ),
              _buildNumberButton('0'),
              _buildActionButton(
                icon: Icons.clear_all,
                onTap: _onClearAll,
                tooltip: 'مسح الكل',
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: () => _onNumberPadTap(number),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Color(0xFFa47764).withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            number,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF633e3d),
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Color(0xFFa47764).withOpacity(0.3)),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 28,
            color: Color(0xFF633e3d),
          ),
        ),
      ),
    );
  }
} 