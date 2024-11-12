import 'package:flutter/material.dart';
import 'package:kokotan/Algorithm/srs.dart' as srs;
import 'package:kokotan/model/deck_list.dart';
import 'package:kokotan/view_models/data_view_model.dart';
import 'package:provider/provider.dart';
import 'word_edit_screen.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ListScreen extends StatefulWidget {
  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen>
    with SingleTickerProviderStateMixin {
  TextEditingController _searchController = TextEditingController();
  int? _selectedDeckID;
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeData();
  }

  Future<void> _initializeData() async {
    // DataViewModel の初期化を待つ
    final viewModel = Provider.of<DataViewModel>(context, listen: false);
    await viewModel.initializeDeckData();
    final availableDecks = viewModel.getAvailableDecks();
    setState(() {
      _selectedDeckID = viewModel.getFirstDeckID(availableDecks) ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DataViewModel>(context);
    final availableDecks = viewModel.getAvailableDecks(); // 利用可能なデッキを取得

    return DefaultTabController(
      length: availableDecks.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('単語リスト'),
          automaticallyImplyLeading: false,
          centerTitle: true,
          actions: [
            // IconButton(
            //   icon: Icon(Icons.refresh),
            //   onPressed: viewModel.refreshList,
            // ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: launchHelpURL,
            ),
          ],
          bottom: TabBar(
            isScrollable: true, // 横スクロール可能に設定
            labelColor: const Color(0xFF333333), // 選択されたタブのテキスト色
            unselectedLabelColor: Colors.grey, // 非選択タブのテキスト色
            indicatorColor: Color.fromARGB(255, 60, 177, 180), // タブ下部のインジケータの色
            indicatorWeight: 4.0, // インジケータの太さ
            indicatorSize: TabBarIndicatorSize.label, // インジケータの幅（タブラベルに合わせる）
            labelStyle: TextStyle(
              fontSize: 18, // 選択されたタブのフォントサイズ
              fontWeight: FontWeight.w700, // フォントの太さ
              fontFamily: 'ZenMaruGothic', // フォントファミリー
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 14, // 非選択タブのフォントサイズ
              fontWeight: FontWeight.w500,
              fontFamily: 'ZenMaruGothic',
            ),
            onTap: (index) {
              setState(() {
                _selectedDeckID = index + 1;
              });
            },
            tabs: availableDecks
                .map((deck) => Tab(text: deck["deckName"]))
                .toList(),
          ),
        ),
        body: Consumer<DataViewModel>(
          builder: (context, viewModel, child) {
            // 選択中のデッキIDに基づく検索結果のフィルタリング
            final filteredResults = viewModel.searchResults
                .where((word) => viewModel.cards.any((card) =>
                    card.word.id == word.id && card.did == _selectedDeckID))
                .toList();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search', // ラベルのテキスト
                        labelStyle: TextStyle(
                          fontFamily: 'ZenMaruGothic',
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700], // ラベルの色
                        ),
                        filled: true,
                        fillColor: Colors.grey[200], // 背景色
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0), // 角丸を追加
                          borderSide: BorderSide.none, // 枠線を非表示
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 20.0), // 内側の余白
                        suffixIcon: IconButton(
                          icon: Icon(Icons.search,
                              color: Colors.grey[600]), // アイコンの色
                          onPressed: () {},
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide(
                              color: Color(0xFF3CB0B4),
                              width: 2.0), // フォーカス時の枠線
                        ),
                      ),
                      onChanged: (query) {
                        viewModel.search(query); // 入力テキストが変化したときの検索処理
                      },
                    ),
                  ),
                  Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                      color: Color.fromARGB(192, 60, 176, 180),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'ID',
                              style: TextStyle(
                                fontFamily: 'ZenMaruGothic',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              '見出し語',
                              style: TextStyle(
                                fontFamily: 'ZenMaruGothic',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '意味',
                              style: TextStyle(
                                fontFamily: 'ZenMaruGothic',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Column(
                              mainAxisSize:
                                  MainAxisSize.min, // Columnのサイズを必要最小限に調整
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '状態',
                                  style: TextStyle(
                                    fontFamily: 'ZenMaruGothic',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                                Text(
                                  '次の復習日',
                                  style: TextStyle(
                                    fontFamily: 'ZenMaruGothic',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )),
                  const Divider(height: 1, thickness: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredResults.length,
                      itemBuilder: (context, index) {
                        final word = filteredResults[index];
                        final card = viewModel.cards.firstWhere(
                          (c) =>
                              c.word.id == word.id && c.did == _selectedDeckID,
                          orElse: () => srs.Card(
                            srs.Word(
                              id: 0,
                              word: '',
                              pronunciation: '',
                              mainMeaning: '',
                              subMeaning: '',
                              sentence: '',
                              sentenceJp: '',
                              wordVoice: '',
                              sentenceVoice: '',
                            ),
                            _selectedDeckID ?? 0,
                          ),
                        );

                        String _getQueueLabel(int queue) {
                          switch (queue) {
                            case 0:
                              return '新規';
                            case 1:
                              return '学習中';
                            case 2:
                              return '復習';
                            default:
                              return '-';
                          }
                        }

                        Color getCardQueueColor(int queue) {
                          switch (queue) {
                            case 0:
                              return Colors.blue;
                            case 1:
                              return Colors.red;
                            case 2:
                              return Colors.green;
                            default:
                              return Colors.grey;
                          }
                        }

                        return GestureDetector(
                          onTap: () {
                            viewModel.setCurrentCard(card);
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
                                bottom: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    (word.id % 10000).toString(),
                                    style: TextStyle(
                                      fontFamily: 'ZenMaruGothic',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: AutoSizeText(
                                    word.word,
                                    style: TextStyle(
                                      fontFamily: 'ZenMaruGothic',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 24, // 基本フォントサイズ
                                    ),
                                    maxLines: 1, // 1行に制限
                                    overflow:
                                        TextOverflow.ellipsis, // 長すぎる場合は省略
                                    minFontSize: 16, // 最小フォントサイズ
                                  ),
                                ),
                                SizedBox(
                                  width: 8,
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    word.mainMeaning,
                                    style: TextStyle(
                                      fontFamily: 'ZenMaruGothic',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        _getQueueLabel(card.queue),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'ZenMaruGothic',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                          color: getCardQueueColor(card.queue),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 0.0),
                                        child: Text(
                                          card.queue == 0
                                              ? '-'
                                              : '${DateTime.fromMillisecondsSinceEpoch(card.due).year}/${DateTime.fromMillisecondsSinceEpoch(card.due).month}/${DateTime.fromMillisecondsSinceEpoch(card.due).day}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'ZenMaruGothic',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
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
      ),
    );
  }
}
