import 'package:flutter/material.dart';
import 'package:kokotan/pages/top_page.dart';
import 'package:kokotan/view_models/data_view_model.dart';
import 'package:provider/provider.dart';

class DeckListPage extends StatefulWidget {
  @override
  DeckListPageState createState() => DeckListPageState();
}

class DeckListPageState extends State<DeckListPage> {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DataViewModel>(context); // viewModelを取得

    // ダミーデータ
    List<Map<String, dynamic>> vocabularies = [
      {
        'title': 'ベーシック',
        'description': 'この単語帳には1000語の単語が含まれています。',
        'level': '入試基礎レベル',
        'isReady': false,
        'isDownloaded': false, // ダウンロード済みかどうか
      },
      {
        'title': 'スタンダードA',
        'description':
            'この単語帳は、シス単basic & ターゲット1400にも、シス単 & ターゲット1900にも登場する1504単語を収録しています。入試の基礎固めはバッチリです。',
        'level': 'MARCH・地方国公立レベル',
        'isReady': true,
        'isDownloaded': viewModel.is20DataDownloaded, //初回リリース用の応急処置
      },
      {
        'title': 'スタンダードB',
        'description': 'この単語帳には500語の単語が含まれています。',
        'level': '早慶・旧帝大レベル',
        'isReady': false,
        'isDownloaded': false,
      },
      {
        'title': 'アドバンス',
        'description': 'この単語帳には500語の単語が含まれています。',
        'level': '早慶上位・東大京大・医学部レベル',
        'isReady': false,
        'isDownloaded': false,
      },
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('単語帳リスト'),
      ),
      body: ListView.builder(
        itemCount: vocabularies.length,
        itemBuilder: (context, index) {
          final vocab = vocabularies[index];

          return Card(
            elevation: vocab['isReady'] ? 4.0 : 1.0,
            color: vocab['isReady'] ? Colors.white : Colors.grey[300],
            child: vocab['isReady']
                ? ExpansionTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vocab['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vocab['level'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey[600],
                          ),
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
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          VocabularyListPage(vocab['title']),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    '単語リストを見る',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blueGrey[400],
                                      decoration: TextDecoration.underline,
                                    ),
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
                          onPressed: vocab['isDownloaded']
                              ? null // ダウンロード済みの場合は無効化
                              : () {
                                  setState(() {
                                    vocab['isDownloaded'] = true; // ダウンロード済みにする
                                  });
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TopPage(fromOnboarding: true),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: vocab['isDownloaded']
                                ? Colors.grey // ダウンロード済みの場合の色
                                : const Color.fromARGB(
                                    255, 86, 151, 141), // ダウンロード可能な場合の色
                            foregroundColor: Colors.white, // テキストやアイコンの色
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                          icon: Icon(vocab['isDownloaded']
                              ? Icons.check
                              : Icons.download), // ダウンロード済みならチェックマーク
                          label: Text(
                              vocab['isDownloaded'] ? 'ダウンロード済み' : 'ダウンロード'),
                        ),
                      ),
                    ],
                  )
                : ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vocab['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vocab['level'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    trailing: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '準備中',
                        style: TextStyle(color: Colors.red),
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
