import 'package:flutter/material.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:provider/provider.dart';

import '../config/environment.dart';
import '../stores/auth_store.dart';
import '../stores/enums_store.dart';
import '../utils/toast_helper.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // Form controllers
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _scaffoldFocusNode = FocusNode();
  
  // Form state
  String _countryCode = 'SY';
  String _phone = '';
  String _name = '';
  int _jobTitle = 0;
  bool _agreeToTerms = false;
  
  // Store instances
  late AuthStore _authStore;
  late EnumsStore _enumsStore;
  
  @override
  void initState() {
    super.initState();
    _authStore = Provider.of<AuthStore>(context, listen: false);
    _enumsStore = Provider.of<EnumsStore>(context, listen: false);
    
    // Load job titles after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJobTitles();
    });
  }
  
  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _scaffoldFocusNode.dispose();
    super.dispose();
  }
  
  Future<void> _loadJobTitles() async {
    await _enumsStore.getJobTitles();
  }
  
  // Handle signup
  Future<void> _handleSignup() async {
    if (!_agreeToTerms) {
      ToastHelper.showToast(context, 'يجب الموافقة على شروط الاستخدام للمتابعة', isError: true);
      return;
    }
    
    if (_phone.isEmpty) {
      ToastHelper.showToast(context, 'يرجى إدخال رقم الهاتف', isError: true);
      return;
    }
    
    if (_name.isEmpty) {
      ToastHelper.showToast(context, 'يرجى إدخال الاسم', isError: true);
      return;
    }
    
    final signupData = {
      'country_code': _countryCode,
      'phone': _phone,
      'name': _name,
      'job_title': _jobTitle,
    };
    
    final result = await _authStore.signup(signupData);
    
    if (!mounted) return;
    
    if (result['success'] == true) {
      ToastHelper.showToast(context, result['message'] ?? 'تمت العملية بنجاح', isError: false);
      
      // Navigate to OTP validation
      Navigator.pushNamed(
        context,
        '/otp_validation',
        arguments: {
          'phone': _phone,
          'countryCode': _countryCode,
          'parent': 'signup',
        },
      );
    } else {
      ToastHelper.showToast(context, result['message'] ?? 'حدث خطأ ما', isError: true);
    }
  }
  
  Future<int?> _showJobTitleModal() {
    return showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Modal header
                Container(
                  height: 60,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF633e3d),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context, null),
                      ),
                      Expanded(
                        child: Text(
                          'اختر المسمى الوظيفي',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Cairo',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the close button
                    ],
                  ),
                ),
                
                // Modal content
                Expanded(
                  child: Consumer<EnumsStore>(
                    builder: (context, enumsStore, child) {
                      if (enumsStore.jobTitlesLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF633e3d)),
                          ),
                        );
                      }
                      
                      if (enumsStore.jobTitlesError != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                enumsStore.jobTitlesError!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Cairo',
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _loadJobTitles(),
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      if (enumsStore.jobTitlesResponse == null || enumsStore.jobTitlesResponse!.isEmpty) {
                        return const Center(
                          child: Text(
                            'لا توجد مسميات وظيفية متاحة',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Cairo',
                              color: Color(0xFF6b7280),
                            ),
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        itemCount: enumsStore.jobTitlesResponse!.length,
                        itemBuilder: (context, index) {
                          final jobTitle = enumsStore.jobTitlesResponse![index];
                          return ListTile(
                            title: Text(
                              jobTitle['name'] ?? '',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            onTap: () {
                              Navigator.pop(context, jobTitle['id'] ?? 0);
                            },
                            trailing: _jobTitle == (jobTitle['id'] ?? 0)
                              ? const Icon(Icons.check, color: Color(0xFF633e3d))
                              : null,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Focus(
          focusNode: _scaffoldFocusNode,
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
          Text(
            'إنشاء حساب جديد',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              color: Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 8),
          Text(
            'يرجى إدخال التفاصيل التالية لإنشاء حسابك',
            style: const TextStyle(
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
            
            const SizedBox(height: 16),
            
            // Name input
            _buildNameInput(),
            
            const SizedBox(height: 16),
            
            // Job title dropdown
            _buildJobTitleDropdown(),
            
            const SizedBox(height: 16),
            
            // Terms checkbox
            _buildTermsCheckbox(),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            countrySelectorNavigator: CountrySelectorNavigator.dialog(
              countries: IsoCode.values.where((iso) => iso.name != 'IL').toList(),
              searchBoxDecoration: InputDecoration(
                filled: true,
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Color(0xFFa47764)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Color(0xFFa47764)),
                ),
                suffixIcon: const Icon(Icons.search),
                hintStyle: const TextStyle(fontFamily: 'Cairo'),
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
          Positioned(
            right: 17,
            child: IgnorePointer(
              child: Text(
                'رقم الهاتف',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: const Color(0xFF9ca3af),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildNameInput() {
    return SizedBox(
      height: 56,
      child: TextFormField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: 'الاسم',
          labelStyle: const TextStyle(
            fontFamily: 'Cairo',
            color: Color(0xFF9ca3af),
          ),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        style: const TextStyle(fontFamily: 'Cairo'),
        textAlign: TextAlign.right,
        onChanged: (value) {
          setState(() {
            _name = value;
          });
        },
      ),
    );
  }
  
  Widget _buildJobTitleDropdown() {
    return Consumer<EnumsStore>(
      builder: (context, enumsStore, child) {
        String selectedJobTitle = 'المسمى الوظيفي';
        
        if (_jobTitle > 0 && enumsStore.jobTitlesResponse != null) {
          final jobTitleData = enumsStore.jobTitlesResponse!.firstWhere(
            (title) => title['id'] == _jobTitle,
            orElse: () => null,
          );
          if (jobTitleData != null) {
            selectedJobTitle = jobTitleData['name'] ?? selectedJobTitle;
          }
        }
        
        return SizedBox(
          height: 56,
          child: GestureDetector(
            onTap: enumsStore.jobTitlesLoading
                ? null
                : () async {
                    FocusScope.of(context).unfocus();
                    final selectedId = await _showJobTitleModal();
                    if (selectedId != null) {
                      setState(() {
                        _jobTitle = selectedId;
                      });
                      _scaffoldFocusNode.requestFocus();
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFa47764)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedJobTitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        color: _jobTitle > 0 ? Colors.black : const Color(0xFF9ca3af),
                      ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  if (enumsStore.jobTitlesLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFa47764)),
                      ),
                    ),
                  if (_jobTitle > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _jobTitle = 0;
                          });
                        },
                        child: const Icon(Icons.close, color: Color(0xFFa47764), size: 20),
                      ),
                    ),
                  const Icon(Icons.arrow_drop_down, color: Color(0xFFa47764)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) {
            setState(() {
              _agreeToTerms = value ?? false;
            });
          },
          activeColor: const Color(0xFFa47764),
          checkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/webview',
                arguments: {
                  'url': Environment.termsUrl,
                  'title': 'شروط الاستخدام',
                },
              );
            },
            child: const Text(
              'أوافق على شروط الإستخدام',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
                color: Color(0xFF633e3d),
                decoration: TextDecoration.underline,
              ),
              textAlign: TextAlign.right,
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
              bool isEnabled = _agreeToTerms &&
                  _phone.isNotEmpty &&
                  _name.isNotEmpty &&
                  _jobTitle > 0 &&
                  !authStore.signupLoading;

              return SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: isEnabled ? _handleSignup : null,
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
                      color: isEnabled ? null : const Color(0xFFbda28c).withOpacity(0.6),
                    ),
                    child: Container(
                      height: 45,
                      alignment: Alignment.center,
                      child: authStore.signupLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'حساب جديد',
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
                'هل لديك حساب؟ ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6b7280),
                  fontFamily: 'Cairo',
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  'تسجيل الدخول',
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