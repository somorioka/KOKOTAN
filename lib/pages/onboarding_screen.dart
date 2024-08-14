import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'top_page.dart'; // TopPageをインポート

class OnboardingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: '',
          bodyWidget: const Text(
            "ココタンは、英単語が勝手に身につく\n「全自動 単語カードアプリ」です",
            style: TextStyle(fontSize: 18.0),
            textAlign: TextAlign.center,
          ),
          image: Center(
            child: Image.asset(
              'assets/images/intro_1.png', // ここに画像のパスを指定
              height: 244,
              width: 366,
            ),
          ),
          decoration: const PageDecoration(
            imagePadding: EdgeInsets.only(top: 100),
            pageColor: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        PageViewModel(
          title: "",
          body: "出てきた単語を\n覚えてる度に応じて仕分けるだけ！",
          image: Center(
            child: Image.asset(
              'assets/images/intro_2.png', // ここに画像のパスを指定
              height: 244,
              width: 366,
            ),
          ),
          decoration: const PageDecoration(
            imagePadding: EdgeInsets.only(top: 100),
            pageColor: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        PageViewModel(
          title: "",
          body: "自動で学習頻度を調整してくれるから\n毎日与えられたカードだけやればOK！",
          image: Center(
            child: Image.asset(
              'assets/images/intro_3.png', // ここに画像のパスを指定
              height: 244,
              width: 366,
            ),
          ),
          decoration: const PageDecoration(
            imagePadding: EdgeInsets.only(top: 10),
            pageColor: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
        PageViewModel(
          title: "",
          body: "早速やってみよう！\nまずは自分のレベルに合わせて\n単語帳を選んでね",
          image: Center(
            child: Image.asset(
              'assets/images/intro_4.png', // ここに画像のパスを指定
              height: 244,
              width: 366,
            ),
          ),
          decoration: const PageDecoration(
              // bodyAlignment: Alignment.bottomCenter,
              imagePadding: EdgeInsets.only(top: 100),
              pageColor: Color.fromARGB(255, 255, 255, 255),
              footerFit: FlexFit.loose),
          // footer: Align(
          //   alignment: Alignment.bottomCenter,
          //   child: Padding(
          //     padding: const EdgeInsets.all(8.0),
          //     child: ElevatedButton(
          //       onPressed: () {
          //         // TopPageへ遷移する
          //         Navigator.pushReplacement(
          //           context,
          //           MaterialPageRoute(builder: (context) => TopPage()),
          //         );
          //       },
          //       child: const Text("はじめる"),
          //     ),
          //   ),
          // ),
        ),
      ],
      onDone: () async {
        // TopPageへ遷移する前に、オンボーディング完了を保存
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasSeenOnboarding', true);
        // TopPageへ遷移する
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const TopPage(fromOnboarding: true)),
        );
      },
      showSkipButton: false,
      skip: const Text("Skip"),
      next: const Icon(Icons.arrow_forward),
      done: const Text("Done", style: TextStyle(fontWeight: FontWeight.w600)),
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
