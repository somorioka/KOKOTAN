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
  final int initialIndex; // 初期インデックスを追加

  const TopPage(
      {super.key, this.fromOnboarding = false, this.initialIndex = 0});

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
    _selectedIndex = widget.initialIndex; // 初期インデックスを設定

    if (widget.fromOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Provider.of<DataViewModel>(context, listen: false)
            .downloadInitialData();
        // Provider.of<DataViewModel>(context, listen: false)
        //     .downloadRemainingDataInBackground();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white, // 背景色を変更
        type: BottomNavigationBarType.fixed,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'リスト',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.query_stats),
            label: '学習状況',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'コラム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'メニュー',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color.fromARGB(255, 60, 177, 180),
        onTap: _onItemTapped,
        selectedLabelStyle: TextStyle(
          fontFamily: 'ZenMaruGothic', // カスタムフォントを適用
          fontWeight: FontWeight.w700, // 太字
          fontSize: 14, // サイズ変更
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'ZenMaruGothic',
          fontWeight: FontWeight.w400, // 標準の太さ
          fontSize: 12,
        ),
      ),
    );
  }
}
