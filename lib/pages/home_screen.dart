import 'package:flutter/material.dart';
import 'package:kokotan/pages/flashcard_screen.dart';
import 'package:kokotan/pages/otsukare.dart';
import 'package:kokotan/view_models/data_view_model.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DataViewModel>(builder: (context, viewModel, child) {
      if (viewModel.scheduler == null) {
        return Center(
          child: CircularProgressIndicator(), // Schedulerが初期化されるのを待つ
        );
      }
      return Scaffold(
          appBar: AppBar(
            title: const Text('ホーム'),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () {},
              ),
            ],
          ),
          body: (viewModel.isLoading)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '単語帳データをダウンロードしています',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(
                      value: viewModel.downloadProgress, // プログレスバーを表示
                    ),
                    const SizedBox(height: 20),
                    Text("${(viewModel.downloadProgress * 100).toInt()}%"),
                  ],
                )
              : Column(
                  children: [
                    Container(
                        height: 241,
                        width: 361,
                        child: Image.asset('assets/images/home_humor1.png')),
                    const SizedBox(height: 32),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: 1,
                        itemBuilder: (context, index) {
                          return Card(
                            child: ListTile(
                              tileColor:
                                  const Color.fromARGB(255, 251, 251, 251),
                              // trailing: Icon(item['icon'] as IconData),
                              title: const Text(
                                "スタンダードA",
                                style: TextStyle(
                                  fontSize: 18,
                                ),
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
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            "あと${viewModel.newCardCount.toString()}枚",
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.chevron_right,
                                      size: 18, // アイコンのサイズを調整
                                    ),
                                    // const Text(
                                    //   '>',
                                    //   style: TextStyle(
                                    //       fontSize: 18,
                                    //       fontWeight: FontWeight.w400),
                                    // ),
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
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                                1, 240, 240, 240), // ボタンの背景色を指定
                            foregroundColor: Colors.white, // テキストやアイコンの色を指定
                          ),
                          onPressed: () {},
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add),
                              SizedBox(width: 8),
                              Text("単語帳を追加"),
                            ],
                          )),
                    ),
                    const SizedBox(height: 16),
                  ],
                ));
    });
  }
}
