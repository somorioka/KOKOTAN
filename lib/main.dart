import 'package:flutter/material.dart';
import 'package:kokotan/pages/top_page.dart';
import 'package:provider/provider.dart';

import 'view_models/data_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await importExcelToDatabase();
  runApp(
    ChangeNotifierProvider(
      create: (context) => DataViewModel(),
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
      home: TopPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
