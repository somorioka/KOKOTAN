import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kokotan/model/deck_list.dart';
import 'package:kokotan/pages/deck_list_page.dart';
import 'package:kokotan/pages/flashcard_screen.dart';
import 'package:kokotan/pages/otsukare.dart';
import 'package:kokotan/view_models/data_view_model.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 使用する画像ファイルのリストを定義
    final List<String> imagePaths = [
      'assets/images/humor_home_1.png',
      'assets/images/humor_home_2.png',
      'assets/images/humor_home_3.png',
      'assets/images/humor_home_4.png',
      'assets/images/humor_home_5.png',
      'assets/images/humor_home_6.png',
      'assets/images/humor_home_7.png',
      'assets/images/humor_home_8.png',
      'assets/images/humor_home_9.png',
    ];

    // ランダムな画像パスを選択して保持
    final randomImage = useState(
      imagePaths[Random().nextInt(imagePaths.length)],
    );

    return FutureBuilder(
      future:
          Provider.of<DataViewModel>(context, listen: false).initializeData(),
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('ホーム'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: launchHelpURL,
              ),
            ],
          ),
          body: Consumer<DataViewModel>(builder: (context, viewModel, child) {
            final filteredDecks = viewModel.deckData.entries.where((entry) {
              return entry.value['isDownloaded'] !=
                  DownloadStatus.notDownloaded;
            }).toList();

            return Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  height: screenHeight * 0.34,
                  width: screenWidth * 0.9,
                  child: Image.asset(
                    randomImage.value,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: filteredDecks.length,
                    itemBuilder: (context, index) {
                      final deck = filteredDecks[index].value;
                      int deckID = int.tryParse(deck['deckID'] ?? '0') ?? 0;
                      String deckName = deck['deckName'] ?? "Unknown Deck";

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 15.0, horizontal: 15),
                          tileColor: const Color.fromARGB(255, 251, 251, 251),
                          title: Text(
                            deckName,
                            style: TextStyle(
                              fontFamily: 'ZenMaruGothic',
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: Color(0xFF333333),
                            ),
                          ),
                          trailing: SizedBox(
                            width: 160,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        '今日できるカード',
                                        style: TextStyle(
                                          fontFamily: 'ZenMaruGothic',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 14,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                      Text(
                                        "あと${viewModel.totalCardCountByDeckID(deckID).toString()}枚",
                                        style: TextStyle(
                                          fontFamily: 'ZenMaruGothic',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 18,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right, size: 18),
                              ],
                            ),
                          ),
                          onTap: () async {
                            viewModel.currentCard =
                                await viewModel.getCard(deckID);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    viewModel.currentCard != null
                                        ? FlashCardScreen(deckID)
                                        : OtsukareScreen(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Consumer<DataViewModel>(
                      builder: (context, viewModel, child) {
                    // deckDataの中に"downloading"があるかチェック
                    final isDownloading = viewModel.deckData.values.any(
                        (deck) =>
                            deck["isDownloaded"] == DownloadStatus.downloading);

                    // ダウンロード中でない場合のみボタンを表示
                    return isDownloading
                        ? SizedBox.shrink() // ダウンロード中なら空のウィジェットを表示
                        : Padding(
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
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),
                          );
                  }),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
              ],
            );
          }),
        );
      },
    );
  }
}
