import 'package:flutter/material.dart';
import 'package:kokotan/pages/flashcard_screen.dart';

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
      home: FlashCardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
