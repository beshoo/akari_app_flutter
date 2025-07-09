import 'package:flutter/material.dart';
import 'dart:async';

class OnboardingSlide {
  final String title;
  final String subtitle;

  OnboardingSlide({
    required this.title,
    required this.subtitle,
  });
}

class ParallaxSlider extends StatefulWidget {
  final double? height;
  
  const ParallaxSlider({
    super.key,
    this.height,
  });

  @override
  State<ParallaxSlider> createState() => _ParallaxSliderState();
}

class _ParallaxSliderState extends State<ParallaxSlider> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  Timer? _autoPlayTimer;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: "إستثمارك بأمان تام",
      subtitle: "استثمر في عقارات المستقبل مع عقاري. منصة آمنة وموثوقة تتيح لك التداول العقاري بكل سهولة، وحماية مدخراتك وبناء مستقبل مالي مستقر",
    ),
    OnboardingSlide(
      title: "عالم العقار بين يديك",
      subtitle: "استكشف عالم العقارات المتنوعة واختر ما يناسبك. منصة عقاري توفر لك كل ما تحتاجه لاتخاذ قرارات استثمارية صائبة، بدءًا من البحث عن العقارات وحتى إتمام الصفقة",
    ),
    OnboardingSlide(
      title: "استثمر واربح مع عقاري",
      subtitle: "حقق أرباحاً مجزية على المدى الطويل من خلال استثماراتك العقارية. عقاري هي منصة الاستثمار الأمثل لنمو ثروتك وتحقيق أهدافك المالية",
    ),
    OnboardingSlide(
      title: "شريكك في عالم العقارات",
      subtitle: "عقاري هو شريكك الأمثل في رحلتك للإستثمار العقاري. نقدم لك الدعم والخبرات اللازمة لاتخاذ القرارات الدقيقة و الصحيحة ، ونضمن لك تجربة استثمارية سلسة وممتعة",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        final nextIndex = (_currentIndex + 1) % _slides.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.ease,
        );
      }
    });
  }

  void _onDotTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.ease,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xfff9f7f4),
            Color(0xfff5f2ed),
            Color(0xffebe5dd),
          ],
        ),
      ),
      child: Column(
        children: [
          // Small gap above logo
          const SizedBox(height: 100),
          
          // Logo area
          SizedBox(
            height: 80,
            child: Center(
              child: Image.asset(
                'assets/images/only_word.png',
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          // Small gap after logo
          const SizedBox(height: 20),
          
          // PageView slider with dots overlay
          Expanded(
            child: Stack(
              children: [
                // PageView slider
                PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildSlide(_slides[index]);
                  },
                ),
                
                // Pagination dots positioned over content
                Positioned(
                  bottom: 100, // 100px bottom gap as requested
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => _buildDot(index),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = index == _currentIndex;
    return GestureDetector(
      onTap: () => _onDotTapped(index),
      child: Container(
        width: 20,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xffd4c2b3) : const Color(0xff774b46),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildSlide(OnboardingSlide slide) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          Text(
            slide.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xff1f2937),
              fontFamily: 'Cairo',
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          
          const SizedBox(height: 24),
          
          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              slide.subtitle,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xff6b7280),
                height: 1.5,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }
} 