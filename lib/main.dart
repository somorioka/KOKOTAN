import 'package:flutter/material.dart';
import 'package:kokotan/pages/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: HomeScreen(
        cardTheme: Color(0xFF00C2FF),
        titleText: 'Daily Study Goal',
        currentStreak: 5,
        lessonsRemaining: 50,
        reviewsRemaining: 10,
        buttonText: 'Quick Study',
        buttonFunction: () {},
        svgPath: 'assets/icons/goal-svgrepo-com.svg',
        svgSize: 50.0,
        progressRadiusOuter: 80.0,
        progressRadiusInner: 60.0,
        lessonColor: Color(0xFF2DD752),
        reviewColor: Color(0xFF9925EA),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
