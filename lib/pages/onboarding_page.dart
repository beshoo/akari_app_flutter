import 'package:flutter/material.dart';

import '../widgets/custom_button.dart';
import '../widgets/parallax_slider.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomNavHeight = 60.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Background ParallaxSlider - takes remaining space
            Expanded(
              child: ParallaxSlider(),
            ),
            
            // Bottom Navigation Bar
            Container(
              height: bottomNavHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Color.fromARGB(255, 217, 218, 220),
                    width: 3,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 4),
              child: Row(
                children: [
                  // Signup Button (Left in RTL)
                  CustomButton(
                    title: "حساب جديد",
                    hasGradient: true,
                    onPressed: () {
                      // Navigate to signup page
                      Navigator.pushNamed(context, '/signup');
                    },
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Login Button (Right in RTL)
                  CustomButton(
                    title: "تسجيل الدخول",
                    hasGradient: false,
                    onPressed: () {
                      // Navigate to login page
                      Navigator.pushNamed(context, '/login');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 