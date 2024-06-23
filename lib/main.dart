import 'package:flutter/material.dart';
import 'package:kokotan/excel_importer.dart';
import 'package:kokotan/pages/flashcard_list_screen.dart';
import 'package:kokotan/pages/flashcard_screen.dart';
import 'package:kokotan/pages/top_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await importExcelToDatabase();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: TopPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
