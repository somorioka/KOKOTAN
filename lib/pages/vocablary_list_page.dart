import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:kokotan/view_models/data_view_model.dart';
import 'dart:io';

class VocabularyListPage extends StatefulWidget {
  final String title;
  final String fileUrl;

  VocabularyListPage(this.title, this.fileUrl);

  @override
  _VocabularyListPageState createState() => _VocabularyListPageState();
}

class _VocabularyListPageState extends State<VocabularyListPage> {
  File? _downloadedFile;

  @override
  void initState() {
    super.initState();
    _downloadFile(widget.fileUrl);
  }

  Future<void> _downloadFile(String url) async {
    try {
      // HTTPリクエストでファイルをダウンロード
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // 一時ディレクトリにファイルを保存
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/downloaded_excel_file.xlsx';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // ダウンロードが成功したらファイルをセットし、インポートを開始
        setState(() {
          _downloadedFile = file;
        });
        context.read<DataViewModel>().importExcelForVocabralyList(file);
      } else {
        print('ダウンロードに失敗しました: ステータスコード ${response.statusCode}');
      }
    } catch (e) {
      print('ファイルのダウンロードエラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} の単語リスト'),
      ),
      body: Consumer<DataViewModel>(
        builder: (context, viewModel, child) {
          if (_downloadedFile == null || viewModel.isLoading) {
            // ファイルがダウンロード中または読み込み中であればローディングインジケータを表示
            return Center(child: CircularProgressIndicator());
          }

          final simpleWords = viewModel.simpleWords;

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
                    itemCount: simpleWords.length,
                    itemBuilder: (context, index) {
                      final word = simpleWords[index];
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
                                ((word.id) % 10000).toString(),
                                style: TextStyle(
                                  fontFamily: 'ZenMaruGothic',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                word.word,
                                style: TextStyle(
                                  fontFamily: 'ZenMaruGothic',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                word.mainMeaning,
                                style: TextStyle(
                                  fontFamily: 'ZenMaruGothic',
                                  fontWeight: FontWeight.w700,
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
