import 'package:akari_app/data/repositories/home_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

import 'pages/login_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/otp_validation_page.dart';
import 'pages/signup_page.dart';
import 'pages/splash_page.dart';
import 'pages/webview_page.dart';
import 'pages/home/home_page.dart';
import 'services/api_service.dart';
import 'services/firebase_messaging_service.dart';
import 'stores/auth_store.dart';
import 'stores/enums_store.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize API service
  ApiService.initialize();
  Get.put(ApiService.instance);
  Get.put(HomeRepository());
  
  // Initialize Firebase messaging and request permission
  await FirebaseMessagingService.instance.initialize();
  
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        // Make sure the back button appears on the correct side for RTL
        centerTitle: true,
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('لقد ضغطت على الزر هذا العدد من المرات:'), // Arabic text
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            const Text(
              'مرحباً بك في تطبيق أكاري!', // Welcome to Akari App!
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'هذا التطبيق يدعم اللغة العربية واتجاه النص من اليمين لليسار', // This app supports Arabic and RTL text direction
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: Text('إنشاء حساب جديد'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Text('تسجيل الدخول'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'زيادة', // Arabic tooltip
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
