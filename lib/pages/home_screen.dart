import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'title': 'ベーシック',
        'subtitle': 'ターゲット1400, システム英単語basicレベル',
        'icon': Icons.check_circle,
      },
      {
        'title': 'スタンダードA',
        'subtitle': 'ターゲット1900, システム英単語 前半レベル',
        'icon': Icons.check_circle,
      },
      {
        'title': 'スタンダードB',
        'subtitle': 'ターゲット1900, システム英単語 後半レベル',
        'icon': Icons.cloud_download,
      },
    ];

    return Column(
      children: [
        Container(
            height: 200,
            width: 200,
            child: Image.asset('assets/images/humor_top.png')),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(8.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: Icon(item['icon'] as IconData?),
                  title: Text(item['title'] as String),
                  subtitle: Text(item['subtitle'] as String),
                  onTap: () {
                    // Implement navigation to item details if needed
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
