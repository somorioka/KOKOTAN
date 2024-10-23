import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:kokotan/pages/deck_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'top_page.dart'; // TopPageをインポート

class OnboardingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: '',
          bodyWidget: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 180), // 画像の上にSizedBox
              Image.asset(
                'assets/images/intro_1.png',
              height: 244,
              width: 366,
            ),
              SizedBox(height: 140), // 画像とテキストの間にSizedBox
              const Text(
                "ココタンは\n英単語が勝手に身につく\n「全自動 単語カードアプリ」です",
                style: TextStyle(
                  fontFamily: 'ZenMaruGothic',
                  fontWeight: FontWeight.w700, // Bold
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          decoration: const PageDecoration(
            pageColor: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        PageViewModel(
          title: "",
          bodyWidget: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 180), // 画像の上にSizedBox
              Image.asset(
                'assets/images/intro_2.png',
              height: 244,
              width: 366,
            ),
              SizedBox(height: 140),
              const Text(
                "出てきた単語を\n覚えてる度に応じて仕分けるだけ！",
                style: TextStyle(
                  fontFamily: 'ZenMaruGothic',
                  fontWeight: FontWeight.w700, // Bold
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          decoration: const PageDecoration(
            pageColor: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        PageViewModel(
          title: "",
          bodyWidget: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 180), // 画像の上にSizedBox
              Image.asset(
                'assets/images/intro_3.png',
              height: 244,
              width: 366,
            ),
              SizedBox(height: 140),
              const Text(
                "自動で学習頻度を調整してくれるから\n毎日与えられたカードだけやればOK！",
                style: TextStyle(
                  fontFamily: 'ZenMaruGothic',
                  fontWeight: FontWeight.w700, // Bold
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          decoration: const PageDecoration(
            pageColor: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        PageViewModel(
          title: "",
          bodyWidget: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 180), // 画像の上にSizedBox
              Image.asset(
                'assets/images/intro_4.png',
              height: 244,
              width: 366,
            ),
              SizedBox(height: 140),
              const Text(
                "早速やってみよう！\nまずは自分のレベルに合わせて\n単語帳を選んでね",
                style: TextStyle(
                  fontFamily: 'ZenMaruGothic',
                  fontWeight: FontWeight.w700, // Bold
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
      onDone: () async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasSeenOnboarding', true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DeckListPage()),
        );
      },
      showSkipButton: false,
      next: const Icon(Icons.arrow_forward),
      done: const Text("はじめる", style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(20.0, 10.0),
        activeColor: Theme.of(context).colorScheme.secondary,
        color: Colors.black26,
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
    );
  }
}
