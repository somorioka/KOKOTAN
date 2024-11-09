import 'package:flutter/material.dart';
import 'package:kokotan/pages/column_screen.dart';
import 'package:kokotan/pages/record_screen.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:math';

import 'package:kokotan/pages/top_page.dart';

class OtsukareScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // 使用する画像ファイルのリストを定義
    final List<String> otsukareImagePaths = [
      'assets/images/humor_otsukare_1.png',
      'assets/images/humor_otsukare_2.png',
      'assets/images/humor_otsukare_3.png',
      'assets/images/humor_otsukare_4.png',
      'assets/images/humor_otsukare_5.png',
      'assets/images/humor_otsukare_6.png',
      'assets/images/humor_otsukare_7.png',
      'assets/images/humor_otsukare_8.png',
      'assets/images/humor_otsukare_9.png',
      'assets/images/humor_otsukare_10.png',
      'assets/images/humor_otsukare_11.png',
      'assets/images/humor_otsukare_12.png',
      'assets/images/humor_otsukare_13.png',
      'assets/images/humor_otsukare_14.png',
      'assets/images/humor_otsukare_15.png',
      'assets/images/humor_otsukare_16.png',
    ];

    // ランダムな画像を選択
    final randomIndex = useState(Random().nextInt(otsukareImagePaths.length));
    final randomImagePath = otsukareImagePaths[randomIndex.value];

    return Scaffold(
      appBar: AppBar(
        title: Text('お疲れ様！'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'やった〜！今日のカードをやりきりました！\n自分自身を褒め称え明日への鋭気を養いましょう！',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          ),
          const SizedBox(height: 30),

          // ランダムに選ばれた画像を表示
          Image.asset(randomImagePath),

          SizedBox(
            height: 20,
          ),
          // 学習状況（RecordScreen）のタブに移動
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 60, 177, 180), // 背景色
              padding: const EdgeInsets.symmetric(
                  vertical: 15.0, horizontal: 30.0), // ボタンのサイズ調整
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // 角丸の設定
              ),
              elevation: 6, // 浮き上がっているような影の深さ
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) {
                  return TopPage(initialIndex: 2); // 必要に応じて初期インデックスを指定
                }),
              );
            },
            child: Text(
              '学習状況をみる',
              style: TextStyle(
                fontFamily: 'ZenMaruGothic',
                fontWeight: FontWeight.w700, // 太字
                fontSize: 20,
                color: Colors.white, // 白色の文字
              ),
            ),
          ),
          SizedBox(
            height: 20,
          ),
          // コラム（ColumnScreen）のタブに移動

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 60, 177, 180), // 背景色
              padding: const EdgeInsets.symmetric(
                  vertical: 15.0, horizontal: 30.0), // ボタンのサイズ調整
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // 角丸の設定
              ),
              elevation: 6, // 浮き上がっているような影の深さ
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) {
                  return TopPage(initialIndex: 3); // 必要に応じて初期インデックスを指定
                }),
              );
            },
            child: Text(
              'コツを知る',
              style: TextStyle(
                fontFamily: 'ZenMaruGothic',
                fontWeight: FontWeight.w700, // 太字
                fontSize: 20,
                color: Colors.white, // 白色の文字
              ),
            ),
          ),
        ],
      ),
    );
  }
}
