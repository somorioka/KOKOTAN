import 'dart:typed_data';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:kokotan/view_models/data_view_model.dart';

class FlashCardScreen extends StatefulWidget {
  @override
  _FlashCardScreenState createState() => _FlashCardScreenState();
}

class _FlashCardScreenState extends State<FlashCardScreen> {
  bool showDetails = false; // 詳細を表示するかどうかのフラグ
  Uint8List? _imageData;
  TextEditingController field = TextEditingController();
  bool haspasted = false;

  String getCardQueueLabel(int queue) {
    switch (queue) {
      case 0:
        return "新規";
      case 1:
        return "学習中";
      case 2:
        return "復習中";
      default:
        return "Unknown";
    }
  }

  void pasteFromClipboard() {
    FlutterClipboard.paste().then((value) {
      setState(() {
        field.text = value;
        haspasted = true;
      });
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error pasting from Clipboard')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataViewModel>(
      builder: (context, viewModel, child) {
        final card = viewModel.currentCard;
        final word = card?.word;
        final currentWord = viewModel.currentWord;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              showDetails = !showDetails;
            });
          },
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (word != null) ...[
                    Padding(
                      padding:
                          EdgeInsets.only(top: 64.0, left: 25.0, bottom: 20.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            word.word,
                            style: TextStyle(
                                fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(Icons.volume_up),
                            tooltip: 'Play sound',
                            onPressed: () {
                              // Play sound logic here
                            },
                          ),
                          Text(
                            '${getCardQueueLabel(card?.queue ?? -1)}',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color.fromARGB(221, 97, 160, 255)),
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: showDetails,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 25.0, right: 25.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 249, 249, 208),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                word.mainMeaning,
                                style: TextStyle(
                                    fontSize: 20, color: Colors.black),
                              ),
                            ),
                            SizedBox(height: 20),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  '${word.sentence}\n${word.sentenceJp}',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.black87),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.volume_up),
                              tooltip: 'Play sound',
                              onPressed: () {
                                // Play sound logic here
                              },
                            ),
                            SizedBox(height: 10),
                            DropRegion(
                              onDropOver: (event) => DropOperation.move,
                              formats: Formats.standardFormats,
                              onPerformDrop: (event) async {
                                final item = event.session.items.first;
                                final reader = item.dataReader!;
                                if (reader.canProvide(Formats.jpeg)) {
                                  reader.getFile(Formats.jpeg, (file) {
                                    file.readAll().then((data) {
                                      setState(() {
                                        _imageData = data;
                                      });
                                    });
                                  }, onError: (error) {
                                    print('Error reading image: $error');
                                  });
                                }
                              },
                              child: _imageData == null
                                  ? Container(
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.blue, width: 2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Image.asset(
                                              'assets/images/add-picture.png',
                                              width: 50,
                                              height: 50),
                                          Text('ここに画像をドロップ！',
                                              style: TextStyle(fontSize: 16)),
                                        ],
                                      ),
                                    )
                                  : Image.memory(_imageData!),
                            ),
                            SizedBox(height: 20),
                            if (haspasted)
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color:
                                      Color.fromARGB(255, 254, 254, 244), // 背景色
                                  border: Border.all(
                                      color: Color.fromARGB(255, 248, 210, 154),
                                      width: 2), // 枠線
                                  borderRadius: BorderRadius.circular(8), // 角丸
                                ),
                                child: Text(
                                  '${field.text}',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            SizedBox(height: 20),
                            ElevatedButton.icon(
                              icon: Icon(Icons.paste, color: Colors.white),
                              onPressed: pasteFromClipboard,
                              label: Text(
                                'ペースト',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(255, 127, 127, 127),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () =>
                  showHalfModal(context, currentWord?.word ?? 'practice'),
              child: Icon(Icons.search),
            ),
            bottomNavigationBar: showDetails
                ? BottomAppBar(
                    color: Colors.blueGrey[50], // 背景色を設定
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        _buildButton(context, 'Again', Colors.red, viewModel),
                        _buildButton(context, 'Hard', Colors.orange, viewModel),
                        _buildButton(context, 'Good', Colors.green, viewModel),
                        _buildButton(context, 'Easy', Colors.blue, viewModel),
                      ],
                    ),
                  )
                : BottomAppBar(
                    color: Colors.blueGrey[50], // 背景色を設定
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text('新規'),
                            Text(
                              viewModel.newCardCount.toString(),
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text('学習中'),
                            Text(
                              viewModel.learningCardCount.toString(),
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text('復習中'),
                            Text(
                              viewModel.reviewCardCount.toString(),
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  void showHalfModal(BuildContext context, String keyword) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height / 2,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('画像検索',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _searchImage(keyword);
                            },
                            child: Text('Google'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _searchImage(keyword);
                            },
                            child: Text('Getty'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _searchImage(keyword);
                            },
                            child: Text('iStock'),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text('辞書を引く',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _searchDictionary(keyword);
                            },
                            child: Text('英次郎'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _searchEnglishDictionary(keyword);
                            },
                            child: Text('Cambridge'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _searchEnglishDictionary(keyword);
                            },
                            child: Text('Oxford'),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text('類義語を検索',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _searchDictionary(keyword);
                            },
                            child: Text('WordNet'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _searchEnglishDictionary(keyword);
                            },
                            child: Text('SKELL'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _searchEnglishDictionary(keyword);
                            },
                            child: Text('Tensai'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _searchImage(String keyword) async {
    final _url = Uri.parse('https://www.google.com/search?tbm=isch&q=$keyword');
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_url');
    }
  }

  void _searchDictionary(String keyword) async {
    final _url = Uri.parse('https://eow.alc.co.jp/$keyword');
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_url');
    }
  }

  void _searchEnglishDictionary(String keyword) async {
    final _url =
        Uri.parse('https://www.ldoceonline.com/jp/dictionary/$keyword');
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_url');
    }
  }

  Widget _buildButton(BuildContext context, String label, Color color,
      DataViewModel viewModel) {
    return ElevatedButton(
      onPressed: () {
        int ease = _getEaseValue(label);
        viewModel.answerCard(ease);
        setState(() {
          showDetails = false;
        });
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(label),
    );
  }

  int _getEaseValue(String label) {
    switch (label) {
      case 'Again':
        return 1;
      case 'Hard':
        return 2;
      case 'Good':
        return 3;
      case 'Easy':
        return 4;
      default:
        return 1;
    }
  }
}
