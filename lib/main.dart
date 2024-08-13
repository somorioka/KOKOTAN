import 'package:flutter/material.dart';
import 'package:kokotan/pages/top_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/onboarding_screen.dart';
import 'view_models/data_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await importExcelToDatabase();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool? hasSeenOnboarding = prefs.getBool('hasSeenOnboarding');
  bool? hasImportedData = prefs.getBool('hasImportedData');

  // DataViewModelのインスタンスを作成
  DataViewModel dataViewModel = DataViewModel();

  if (hasImportedData == null || !hasImportedData) {
    // 初回起動時のみデータをダウンロード・インポート
    await dataViewModel.downloadAndImportExcel();
    await prefs.setBool('hasImportedData', true); // 実行済みとして記録
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => DataViewModel()..initializeData(),
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
        useMaterial3: true,
      ),
      home: hasSeenOnboarding ? TopPage() : OnboardingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
