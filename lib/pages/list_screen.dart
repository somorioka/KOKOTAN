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

                          return ListTile(
                            title: Text(word.word),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('id: ${word.id}'),
                                Text('意味: ${word.mainMeaning}'),
                                Text('意味(サブ): ${word.subMeaning}'),
                                Text('例文: ${word.sentence}'),
                                Text('例文意味: ${word.sentenceJp}'),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Card ID: ${card.id}'),
                                    Text(
                                        '次の期限: ${DateTime.fromMillisecondsSinceEpoch(card.due)}'),
                                    Text('type: ${card.type}'),
                                    Text('Queue: ${card.queue}'),
                                    Text('Interval: ${card.ivl}'),
                                    Text('Factor: ${card.factor}'),
                                    Text('Repetitions: ${card.reps}'),
                                    Text('Lapses: ${card.lapses}'),
                                    Text('left: ${card.left}')
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              // Implement navigation to card details if needed
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }
}
