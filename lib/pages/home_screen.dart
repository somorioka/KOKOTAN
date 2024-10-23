import 'package:flutter/material.dart';
import 'package:kokotan/pages/deck_list_page.dart';
import 'package:kokotan/pages/flashcard_screen.dart';
import 'package:kokotan/pages/otsukare.dart';
import 'package:kokotan/view_models/data_view_model.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // DataViewModel の initializeData() がダウンロード処理
      future:
          Provider.of<DataViewModel>(context, listen: false).initializeData(),
      builder: (context, snapshot) {
      return Scaffold(
          appBar: AppBar(
            title: const Text('ホーム'),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: launchHelpURL,
              ),
            ],
          ),
          body: Consumer<DataViewModel>(builder: (context, viewModel, child) {
            return (viewModel.is20DataDownloaded == false)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                        '単語帳データを20枚だけ先に\nダウンロードしています',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: LinearProgressIndicator(
                          value: viewModel.downloadProgress,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blueAccent,
                          ),
                        ),
                    ),
                    const SizedBox(height: 20),
                      Text(
                        "${(viewModel.downloadProgress * 100).toInt()}%",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333)),
                      ),
                  ],
                )
              : Column(
                  children: [
                      const SizedBox(height: 16),
                    Container(
                        height: 241,
                        width: 361,
                        child: Image.asset('assets/images/home_humor1.png'),
                      ),
                      const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: 1,
                        itemBuilder: (context, index) {
                          return Card(
                            child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 15.0,
                                    horizontal: 15), // 縦のパディングを追加
                              tileColor:
                                  const Color.fromARGB(255, 251, 251, 251),
                              title: const Text(
                                "スタンダードA",
                                style: TextStyle(
                                      fontFamily: 'ZenMaruGothic',
                                      fontWeight: FontWeight.w700, // Bold
                                      fontSize: 20,
                                      color: Color(0xFF333333)),
                              ),
                              trailing: SizedBox(
                                width: 160,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            '今日できるカード',
                                            style: TextStyle(
                                                  fontFamily: 'ZenMaruGothic',
                                                  fontWeight:
                                                      FontWeight.w400, // Bold
                                              fontSize: 14,
                                                  color: Color(0xFF333333)),
                                          ),
                                          Text(
                                              "あと${viewModel.totalCardCount.toString()}枚",
                                              style: TextStyle(
                                                  fontFamily: 'ZenMaruGothic',
                                                  fontWeight:
                                                      FontWeight.w400, // Bold
                                                  fontSize: 18,
                                                  color: Color(0xFF333333)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.chevron_right,
                                        size: 18,
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        viewModel.newCardCount == 0 &&
                                                viewModel.learningCardCount ==
                                                    0 &&
                                                viewModel.reviewCardCount == 0
                                            ? OtsukareScreen()
                                            : FlashCardScreen(),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      // "単語帳を追加する"ボタン
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DeckListPage(),
                              ),
                            );
                          },
                          child: const Text(
                            '単語帳を追加する',
                            style: TextStyle(
                                fontFamily: 'ZenMaruGothic',
                                fontWeight: FontWeight.w400, // Bold
                                fontSize: 16,
                                color: Color(0xFF333333)),
                          ),
                        ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  );
          }),
        );
      },
    );
  }
}
