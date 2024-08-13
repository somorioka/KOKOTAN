import 'package:flutter/material.dart';
import 'package:kokotan/pages/top_page.dart';
import 'package:provider/provider.dart';

import 'pages/onboarding_screen.dart';
import 'view_models/data_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await importExcelToDatabase();
  runApp(
    ChangeNotifierProvider(
      create: (context) => DataViewModel()..initializeData(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: OnboardingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
