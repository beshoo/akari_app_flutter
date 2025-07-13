import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_app_bar.dart';
import 'apartment_form_page.dart';

class ApartmentDemoPage extends StatelessWidget {
  const ApartmentDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5F2),
        appBar: CustomAppBar(
          onBackPressed: () => Navigator.of(context).pop(),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'تطبيق إدارة العقارات',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 32),
              
              // Create new apartment button
              CustomButton(
                title: 'إضافة إعلان عقار جديد',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ApartmentFormPage(
                        mode: ApartmentFormMode.create,
                      ),
                    ),
                  );
                },
                hasGradient: true,
                gradientColors: const [
                  Color(0xFF633E3D),
                  Color(0xFF774B46),
                  Color(0xFF8D5E52),
                  Color(0xFFA47764),
                  Color(0xFFBDA28C),
                ],
                height: 50,
              ),
              
              const SizedBox(height: 16),
              
              // Note about update mode
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Text(
                  'ملاحظة: لتحديث عقار موجود، استخدم ApartmentFormPage مع mode: ApartmentFormMode.update وتمرير البيانات الموجودة',
                  style: TextStyle(
                    color: Colors.blue,
                    fontFamily: 'Cairo',
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 