import 'package:flutter/material.dart';

import 'column_screen.dart';
import 'home_screen.dart';
import 'list_screen.dart';
import 'record_screen.dart';
import 'setting_screen.dart';

class TopPage extends StatefulWidget {
  @override
  _TopPageState createState() => _TopPageState();
}

class _TopPageState extends State<TopPage> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
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
