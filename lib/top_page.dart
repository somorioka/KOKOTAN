import 'package:flutter/material.dart';
import 'package:kokotan/word_page.dart';

class TopPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ここたん'),
        backgroundColor: Colors.grey,
      ),
      body: ListView.separated(
        itemCount: 10, // 10個のリストアイテムを表示
        separatorBuilder: (context, index) => Divider(), // 区切り線を追加
        itemBuilder: (context, index) {
          // 各グループの範囲を計算
          int startIndex = index * 100 + 1;
          int endIndex = (index + 1) * 100;
          return ListTile(
            title: Text('$startIndex - $endIndex'),
            trailing: const Icon(Icons.navigate_next),
            onTap: () {
              // タップされたリストアイテムに対応するグループの単語画面に遷移
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WordPage(startIndex, endIndex),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
