import 'package:flutter/material.dart';
import 'package:kokotan/pages/top_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/onboarding_screen.dart';
import 'view_models/data_view_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? hasSeenOnboarding = prefs.getBool('hasSeenOnboarding');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => DataViewModel(),
      child: MyApp(hasSeenOnboarding: hasSeenOnboarding ?? false),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;

  MyApp({required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          progressIndicatorTheme: ProgressIndicatorThemeData(
            color: Color.fromARGB(255, 60, 177, 180), // インジケーターの色を青に設定
          ),
          scaffoldBackgroundColor: Color(0xFFF8F8F8), // 背景色を統一
          useMaterial3: true,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                  Color.fromARGB(255, 240, 240, 240)), // 背景色
              foregroundColor: MaterialStateProperty.all<Color>(
                  Color.fromARGB(255, 70, 70, 70)), // 文字色
              padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                  EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0)),
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0), // 四角めに
                ),
              ),
            ),
          ),
          appBarTheme: AppBarTheme(
            titleTextStyle: TextStyle(
              fontFamily: 'ZenMaruGothic',
              fontWeight: FontWeight.w700, // Light
              fontSize: 22, // Adjusted font size for better readability
              color:
                  Color(0xFF3CB1B4), // Use the desired color code without ARGB
            ),
            backgroundColor:
                Colors.white, // Example to set the background color to white
            iconTheme: IconThemeData(
                color: Color(0xFF3CB1B4)), // Match the color of icons
          ),
        ),
        home: hasSeenOnboarding ? TopPage() : OnboardingPage(),
        debugShowCheckedModeBanner: false);
  }
}
