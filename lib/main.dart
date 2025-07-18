import 'package:akari_app/data/repositories/home_repository.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import 'pages/home/home_page.dart';
import 'pages/login_page.dart';
import 'pages/notifications_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/otp_validation_page.dart';
import 'pages/signup_page.dart';
import 'pages/splash_page.dart';
import 'pages/webview_page.dart';
import 'services/api_service.dart';
import 'services/firebase_messaging_service.dart';
import 'services/version_service.dart';
import 'stores/auth_store.dart';
import 'stores/enums_store.dart';
import 'stores/reaction_store.dart';
import 'utils/logger.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  Logger.log('📱 Background message received: ${message.messageId}');
  Logger.log('📱 Background message data: ${message.data}');
  if (message.notification != null) {
    Logger.log('📱 Background notification: ${message.notification!.title} - ${message.notification!.body}');
  }
}

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    
    // Initialize Firebase Analytics
    FirebaseAnalytics.instance;
    Logger.log('✅ Firebase Analytics initialized');
    
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e, stack) {
    Logger.log('Firebase initialization failed: '
        '\nError: '
        '\ne.toString()'
        '\nStack: '
        '\nstack');
  }
  
  // Initialize API service
  ApiService.initialize();
  Get.put(ApiService.instance);
  Get.put(HomeRepository());
  
  // Initialize version service and try to get PackageInfo early
  Get.put(VersionService.instance);
  
  // Try to initialize PackageInfo early to avoid issues later
  try {
    await VersionService.getPackageInfo();
    Logger.log('✅ Main: PackageInfo initialized successfully');
  } catch (e) {
    Logger.log('⚠️ Main: Failed to initialize PackageInfo early: $e');
  }
  
  // Initialize Firebase messaging and request permission
  try {
    await FirebaseMessagingService.instance.initialize();
  } catch (e, stack) {
    Logger.log('Firebase Messaging initialization failed: '
        '\nError: '
        '\ne.toString()'
        '\nStack: '
        '\nstack');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthStore()),
        ChangeNotifierProvider(create: (_) => EnumsStore()),
        ChangeNotifierProvider(create: (_) => ReactionStore()),
      ],
      child: ToastificationWrapper(
      child: GetMaterialApp(
        title: 'Akari App',
        debugShowCheckedModeBanner: false,
        
        // RTL Configuration
        locale: const Locale('ar', 'SA'), // Arabic Saudi Arabia
        supportedLocales: const [
          Locale('ar', 'SA'), // Arabic
          Locale('en', 'US'), // English
          Locale('fa', 'IR'), // Persian
        ],
        
        // Add localization delegates
        localizationsDelegates: const [
          ...PhoneFieldLocalization.delegates,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        
        // Force RTL layout direction
        builder: (context, child) {
          final mediaQueryData = MediaQuery.of(context);
          return Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: mediaQueryData.copyWith(
                textScaler: const TextScaler.linear(1.0),
              ),
              child: child!,
            ),
          );
        },
        
        theme: ThemeData(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: _FadePageTransitionsBuilder(),
              TargetPlatform.iOS: _FadePageTransitionsBuilder(),
              TargetPlatform.linux: _FadePageTransitionsBuilder(),
              TargetPlatform.macOS: _FadePageTransitionsBuilder(),
              TargetPlatform.windows: _FadePageTransitionsBuilder(),
            },
          ),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff633e3d)),
          fontFamily: 'Cairo',
          
          // Ensure text theme supports RTL with Cairo font
          textTheme: const TextTheme().apply(
            bodyColor: Colors.black87,
            displayColor: Colors.black87,
            fontFamily: 'Cairo',
          ),
          
          // Customize app bar theme
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xff633e3d),
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
            centerTitle: true,
          ),
          
          // Customize elevated button theme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff633e3d),
              foregroundColor: Colors.white,
              textStyle: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          // Customize input decoration theme
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFa47764)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFd1d5db)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFFa47764)),
            ),
            labelStyle: TextStyle(
              fontFamily: 'Cairo',
              color: Color(0xFF6b7280),
            ),
            hintStyle: TextStyle(
              fontFamily: 'Cairo',
              color: Color(0xFF9ca3af),
            ),
          ),
        ),
        
        home: const SplashPage(),
        
        routes: {
          '/signup': (context) => const SignupPage(),
          '/login': (context) => const LoginPage(),
          '/onboarding': (context) => const OnboardingPage(),
          '/home': (context) => const HomePage(),
          '/notifications': (context) => const NotificationsPage(),
        },
        
        onGenerateRoute: (settings) {
          // Handle dynamic routes
          if (settings.name == '/otp_validation') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => OtpValidationPage(
                phone: args['phone'],
                countryCode: args['countryCode'],
                parent: args['parent'],
              ),
            );
          }
          
          if (settings.name == '/webview') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => WebViewPage(
                url: args['url'],
                title: args['title'],
              ),
            );
          }
          
          // Return null to use default route handling
          return null;
        },
        ),
      ),
    );
  }
}

class _FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}