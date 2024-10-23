import 'package:flutter/material.dart';
import 'package:kokotan/Algorithm/srs.dart' as srs;
import 'package:kokotan/view_models/data_view_model.dart';
import 'package:provider/provider.dart';
import 'word_edit_screen.dart'; // 編集画面のインポート

class ListScreen extends StatefulWidget {
  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DataViewModel>(context); // viewModelを取得

    return Scaffold(
      appBar: AppBar(
        title: Text('単語リスト'),
        centerTitle: true, // タイトルを中央に配置
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: viewModel.refreshList, // 更新ボタン
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: launchHelpURL,
          ),
        ],
      ),
      body: Consumer<DataViewModel>(
        builder: (context, viewModel, child) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                // 検索バー
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed: () {},
                          ),
                        ),
                        onChanged: (query) {
                          viewModel.search(query);
                        },
                      ),
                    ),

                // 見出し行
                Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                  color: Color.fromARGB(192, 60, 176, 180), // 柔らかい背景色
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'ID',
                          style: TextStyle(
                              fontFamily: 'ZenMaruGothic',
                              fontWeight: FontWeight.w700, // Bold
                              fontSize: 18,
                              color: Colors.white),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          '見出し語',
                          style: TextStyle(
                              fontFamily: 'ZenMaruGothic',
                              fontWeight: FontWeight.w700, // Bold
                              fontSize: 18,
                              color: Colors.white),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '次の復習日',
                          style: TextStyle(
                              fontFamily: 'ZenMaruGothic',
                              fontWeight: FontWeight.w700, // Bold
                              fontSize: 18,
                              color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '状態',
                          style: TextStyle(
                              fontFamily: 'ZenMaruGothic',
                              fontWeight: FontWeight.w700, // Bold
                              fontSize: 18,
                              color: Colors.white),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),

                // リスト表示
                    Expanded(
                      child: ListView.builder(
                        itemCount: viewModel.searchResults.length,
                        itemBuilder: (context, index) {
                          final word = viewModel.searchResults[index];
                          final card = viewModel.cards.firstWhere(
                            (c) => c.word.id == word.id,
                            orElse: () => srs.Card(srs.Word(
                              id: 0,
                              word: '',
                              pronunciation: '',
                              mainMeaning: '',
                              subMeaning: '',
                              sentence: '',
                              sentenceJp: '',
                              wordVoice: '',
                              sentenceVoice: '',
                            )),
                          );

                      // ラベルを返すヘルパーメソッド
                      String _getQueueLabel(int queue) {
                        switch (queue) {
                          case 0:
                            return '新規';
                          case 1:
                            return '学習中';
                          case 2:
                            return '復習';
                          default:
                            return '-'; // 万が一他の値が入ってきた場合のデフォルト
                        }
                      }

                      Color getCardQueueColor(int queue) {
                        switch (queue) {
                          case 0: // 新規
                            return Colors.blue;
                          case 1: // 学習中
                            return Colors.red;
                          case 2: // 復習
                            return Colors.green;
                          default: // その他
                            return Colors.grey;
                        }
                      }

                      return GestureDetector(
                        onTap: () {
                          final viewModel = Provider.of<DataViewModel>(context,
                              listen: false);

                          // viewModelのcurrentCardをリストで選んだカードに変更
                          viewModel.setCurrentCard(
                              card); // viewModel.currentCard をリストで選んだカードに更新

                          // WordEditScreenに遷移
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => WordEditScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 16.0, horizontal: 8.0),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom:
                                  BorderSide(color: Colors.grey[300]!), // 下線を追加
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline:
                                TextBaseline.alphabetic, // アルファベットのベースラインで揃える
                            children: [
                              Expanded(
                                flex: 2, // 各要素の比率を設定
                                child: Text(
                                  word.id.toString(),
                                  style: TextStyle(
                                    fontFamily: 'ZenMaruGothic',
                                    fontWeight: FontWeight.w500, // Bold
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 4, // 各要素の比率を設定
                                child: Text(
                                  word.word,
                                  style: TextStyle(
                                    fontFamily: 'ZenMaruGothic',
                                    fontWeight: FontWeight.w700, // Bold
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  card.queue == 0
                                      ? '-'
                                      : '${DateTime.fromMillisecondsSinceEpoch(card.due).year}/${DateTime.fromMillisecondsSinceEpoch(card.due).month}/${DateTime.fromMillisecondsSinceEpoch(card.due).day}', // 年/月/日で表示
                                  textAlign: TextAlign.center, // 期日を中央寄せ
                                  style: TextStyle(
                                    fontFamily: 'ZenMaruGothic',
                                    fontWeight: FontWeight.w500, // Bold
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3, // キューは3文字分の幅を確保
                                child: Text(
                                  _getQueueLabel(card.queue), // queueに応じたラベルを取得
                                  textAlign: TextAlign.right, // 右寄せ
                                  style: TextStyle(
                                    fontFamily: 'ZenMaruGothic',
                                    fontWeight: FontWeight.w500, // Bold
                                    fontSize: 18,
                                    color: getCardQueueColor(card?.queue ?? -1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                          );
                        },
                      ),
                    ),
                  ],
            ),
                );
        },
      ),
    );
  }
}
