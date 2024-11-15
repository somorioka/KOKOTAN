import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:kokotan/pages/deck_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final introKey = GlobalKey<IntroductionScreenState>();
  int currentIndex = 0; // 現在のページインデックスを追跡

  @override
  Widget build(BuildContext context) {
    final pages = [
      PageViewModel(
        title: '',
        bodyWidget: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/intro_1.png',
                height: 244,
                width: 366,
              ),
              SizedBox(height: 40), // 画像とテキストの間にSizedBox
              const Text(
                "ココタンは\n英単語が勝手に身につく\n「全自動 単語カードアプリ」です",
                style: TextStyle(
                  fontFamily: 'ZenMaruGothic',
                  fontWeight: FontWeight.w700, // 太字
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        decoration: const PageDecoration(
          pageColor: Color.fromARGB(255, 255, 255, 255),
          contentMargin: EdgeInsets.symmetric(vertical: 80.0), // マージンを調整
        ),
      ),
      // 他のPageViewModelも同様に追加
      PageViewModel(
        title: "",
        bodyWidget: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/intro_2.png',
              height: 244,
              width: 366,
            ),
            SizedBox(height: 40),
            const Text(
              "出てきた単語を\n覚えてる度に応じて仕分けるだけ！",
              style: TextStyle(
                fontFamily: 'ZenMaruGothic',
                fontWeight: FontWeight.w700, // 太字
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        decoration: const PageDecoration(
          pageColor: Color.fromARGB(255, 255, 255, 255),
          contentMargin: EdgeInsets.symmetric(vertical: 80.0),
        ),
      ),
      PageViewModel(
        title: "",
        bodyWidget: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/intro_3.png',
              height: 244,
              width: 366,
            ),
            SizedBox(height: 40),
            const Text(
              "自動で学習頻度を調整してくれるから\n毎日与えられたカードだけやればOK！",
              style: TextStyle(
                fontFamily: 'ZenMaruGothic',
                fontWeight: FontWeight.w700, // 太字
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        decoration: const PageDecoration(
          pageColor: Color.fromARGB(255, 255, 255, 255),
          contentMargin: EdgeInsets.symmetric(vertical: 80.0),
        ),
      ),
      PageViewModel(
        title: "",
        bodyWidget: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/intro_4.png',
              height: 244,
              width: 366,
            ),
            SizedBox(height: 40),
            const Text(
              "早速やってみよう！\nまずは自分のレベルに合わせて\n単語帳を選んでね",
              style: TextStyle(
                fontFamily: 'ZenMaruGothic',
                fontWeight: FontWeight.w700, // 太字
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        decoration: const PageDecoration(
          pageColor: Color.fromARGB(255, 255, 255, 255),
          contentMargin: EdgeInsets.symmetric(vertical: 80.0),
        ),
      ),
    ];

    return IntroductionScreen(
      key: introKey, // キーを設定
      pages: pages,
      onDone: () {}, // 直接ナビゲーションを行うため、空にします
      showSkipButton: false,
      showNextButton: false, // デフォルトの「次へ」ボタンを非表示にする
      showDoneButton: false, // デフォルトの「はじめる」ボタンを非表示にする
      onChange: (index) {
        setState(() {
          currentIndex = index; // ページが変更されるたびにインデックスを更新
        });
      },
      globalFooter: Container(
        width: double.infinity,
        height: 60.0,
        margin:
            EdgeInsets.only(top: 10.0, bottom: 46.0, left: 24.0, right: 24.0),
        child: ElevatedButton(
          onPressed: () async {
            if (currentIndex == pages.length - 1) {
              // 最終ページの場合、直接ナビゲーションを行う
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hasSeenOnboarding', true);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => DeckListPage()),
              );
            } else {
              // 次のページへ
              introKey.currentState?.next();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 60, 177, 180), // 背景色
            padding: const EdgeInsets.symmetric(
                vertical: 15.0, horizontal: 30.0), // ボタンのサイズ調整
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // 角丸の設定
            ),
            elevation: 6, // 浮き上がっているような影の深さ
          ),
          child: Text(
            currentIndex == pages.length - 1 ? "はじめる" : "次へ",
            style: TextStyle(
                fontFamily: 'ZenMaruGothic',
                fontWeight: FontWeight.w700, // Bold
                fontSize: 20,
                color: Colors.white),
          ),
        ),
      ),
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(20.0, 10.0),
        activeColor: Color.fromARGB(255, 60, 177, 180), // アクティブなドットの色を変更
        color: Colors.grey, // 非アクティブなドットの色
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
    );
  }
}
