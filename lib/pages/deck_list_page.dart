import 'package:flutter/material.dart';
import 'package:kokotan/pages/deck_downloading_page.dart';
import 'package:kokotan/pages/top_page.dart';
import 'package:kokotan/view_models/data_view_model.dart';
import 'package:provider/provider.dart';
import 'package:kokotan/model/deck_list.dart';

class DeckListPage extends StatefulWidget {
  @override
  DeckListPageState createState() => DeckListPageState();
}

class DeckListPageState extends State<DeckListPage> {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DataViewModel>(context); // viewModelを取得

    // デッキリスト（MapのデータをListに変換）
    List<Map<String, dynamic>> deckListItems =
        viewModel.deckData.entries.map((entry) {
      // MapからListに変換しつつデッキIDも追加
      return {
        'deckId': entry.key, // デッキIDを追加
        ...entry.value, // 他のデータを展開
      };
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('単語帳リスト'),
      ),
      body: ListView.builder(
        itemCount: InitialDeckData.length,
        itemBuilder: (context, index) {
          final vocab = deckListItems[index];

          return Card(
            elevation: vocab['isReady'] ? 4.0 : 1.0,
            color: vocab['isReady'] ? Colors.white : Colors.grey[300],
            child: vocab['isReady']
                ? ExpansionTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vocab['deckName'],
                          style: TextStyle(
                              fontFamily: 'ZenMaruGothic',
                              fontWeight: FontWeight.w700, // Bold
                              fontSize: 20,
                              color: Color(0xFF333333)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vocab['level'],
                          style: TextStyle(
                              fontFamily: 'ZenMaruGothic',
                              fontWeight: FontWeight.w500, // Bold
                              fontSize: 14,
                              color: Color(0xFF333333)),
                        ),
                      ],
                    ),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vocab['description'],
                              style: TextStyle(
                                  fontFamily: 'ZenMaruGothic',
                                  fontWeight: FontWeight.w400, // Bold
                                  fontSize: 16,
                                  color: Color(0xFF333333)),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          VocabularyListPage(vocab['deckName']),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    '単語リストを見る',
                                    style: TextStyle(
                                        fontFamily: 'ZenMaruGothic',
                                        fontWeight: FontWeight.w700, // Bold
                                        fontSize: 16,
                                        decoration:
                                            TextDecoration.underline, // アンダーライン
                                        color: Colors.blue),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: vocab['isDownloaded'] ==
                                  DownloadStatus.downloaded
                              ? null // ダウンロード済みの場合は無効化
                              : vocab['isDownloaded'] ==
                                      DownloadStatus.downloading
                                  ? null // ダウンロード中も無効化
                                  : () async {
                                      viewModel.updateDownloadStatus(
                                          vocab['deckId'],
                                          DownloadStatus.downloading);

                                      // 状態を保存
                                      await viewModel
                                          .saveDeckData(viewModel.deckData);

                                      // ダウンロード進捗ページに遷移
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DownloadProgressPage(
                                            deckID: int.parse(vocab['deckId']),
                                          ),
                                        ),
                                      );
                                    },

                          style: ElevatedButton.styleFrom(
                            backgroundColor: vocab['isDownloaded'] ==
                                    DownloadStatus.downloaded
                                ? Colors.grey // ダウンロード済み
                                : vocab['isDownloaded'] ==
                                        DownloadStatus.downloading
                                    ? Colors.blueGrey // ダウンロード中
                                    : const Color.fromARGB(
                                        255, 60, 177, 180), // ダウンロード可能な場合の色
                            foregroundColor: Colors.white, // テキストやアイコンの色

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), // 角丸の設定
                            ),
                            elevation: 6, // 浮き上がっているような影の深さ
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                          icon: vocab['isDownloaded'] ==
                                  DownloadStatus.downloaded
                              ? Icon(Icons.check)
                              : vocab['isDownloaded'] ==
                                      DownloadStatus.downloading
                                  ? Icon(Icons.hourglass_empty) // ダウンロード中のアイコン
                                  : Icon(Icons.download), // ダウンロード可能なアイコン
                          label: Text(
                            style: TextStyle(
                                fontFamily: 'ZenMaruGothic',
                                fontWeight: FontWeight.w700, // Bold
                                fontSize: 20,
                                color: Color.fromARGB(255, 255, 255, 255)),
                            vocab['isDownloaded'] == DownloadStatus.downloaded
                                ? 'ダウンロード済み'
                                : vocab['isDownloaded'] ==
                                        DownloadStatus.downloading
                                    ? 'ダウンロード中'
                                    : 'ダウンロード', // ダウンロード可能な状態
                          ),
                        ),
                      )
                    ],
                  )
                : ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vocab['deckName'],
                          style: TextStyle(
                              fontFamily: 'ZenMaruGothic',
                              fontWeight: FontWeight.w700, // Bold
                              fontSize: 20,
                              color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vocab['level'],
                          style: TextStyle(
                              fontFamily: 'ZenMaruGothic',
                              fontWeight: FontWeight.w500, // Bold
                              fontSize: 14,
                              color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '準備中',
                        style: TextStyle(
                            fontFamily: 'ZenMaruGothic',
                            fontWeight: FontWeight.w500, // Bold
                            fontSize: 16,
                            color: Colors.red),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

// 単語リストページ

class VocabularyListPage extends StatelessWidget {
  final String title;

  VocabularyListPage(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$title の単語リスト'),
      ),
      body: Consumer<DataViewModel>(
        builder: (context, viewModel, child) {
          final words = viewModel.words; // viewModelから単語リストを取得

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // 見出し部分
                Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                  color: Colors.blueGrey[50],
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'ID',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          '単語',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          '意味',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1),
                // 単語リスト部分
                Expanded(
                  child: ListView.builder(
                    itemCount: words.length,
                    itemBuilder: (context, index) {
                      final word = words[index];
                      return Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 8.0),
                        decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Colors.grey[300]!)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                word.id.toString(), // ID
                                style: TextStyle(
                                  fontFamily: 'ZenMaruGothic',
                                  fontWeight: FontWeight.w700, // Bold
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                word.word, // 単語
                                style: TextStyle(
                                  fontFamily: 'ZenMaruGothic',
                                  fontWeight: FontWeight.w700, // Bold
                                  fontSize: 22,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                word.mainMeaning, // メイン訳
                                style: TextStyle(
                                  fontFamily: 'ZenMaruGothic',
                                  fontWeight: FontWeight.w700, // Bold
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
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
