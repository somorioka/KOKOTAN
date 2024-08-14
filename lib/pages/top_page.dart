import 'package:flutter/material.dart';
import 'package:kokotan/view_models/data_view_model.dart';
import 'package:provider/provider.dart';

import 'column_screen.dart';
import 'home_screen.dart';
import 'list_screen.dart';
import 'record_screen.dart';
import 'setting_screen.dart';

class TopPage extends StatefulWidget {
  final bool fromOnboarding;

  const TopPage({super.key, this.fromOnboarding = false});

  @override
  _TopPageState createState() => _TopPageState();
}

class _TopPageState extends State<TopPage> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ListScreen(),
    RecordScreen(),
    ColumnScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.fromOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Provider.of<DataViewModel>(context, listen: false)
            .downloadAndImportExcel();
        Provider.of<DataViewModel>(context, listen: false)
            .downloadRemainingDataInBackground();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '単語リスト',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.query_stats),
            label: '記録',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'コラム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color.fromARGB(255, 32, 195, 148),
        onTap: _onItemTapped,
      ),
    );
  }
}
