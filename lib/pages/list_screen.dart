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
          return viewModel.isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text('Downloading...'),
                    ],
                  ),
                )
              : Column(
                  children: [
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
