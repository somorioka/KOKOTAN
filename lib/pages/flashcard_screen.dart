import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();

  String getCardQueueLabel(int queue) {
    switch (queue) {
      case 0:
        return "未学習";
      case 1:
        return "覚え中";
      case 2:
        return "復習";
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

  // 音声再生のメソッド
  Future<void> _playVoice(String? voicePath) async {
    if (voicePath != null && voicePath.isNotEmpty) {
      final file = File(voicePath);
      if (await file.exists()) {
        try {
          await _audioPlayer.play(DeviceFileSource(voicePath)); // デバイスのファイルを再生
        } catch (e) {
          print('Error playing audio: $e');
        }
      } else {
        print('File not found at path: $voicePath');
      }
    } else {
      print('音声ファイルが見つかりません');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataViewModel>(
      builder: (context, viewModel, child) {
        final card = viewModel.currentCard;
        final word = card?.word;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              showDetails = !showDetails;
            });
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text('Flash Card'),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    showSettingsModal(context);
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (word != null) ...[
                    Padding(
                      padding:
                          EdgeInsets.only(top: 8.0, left: 25.0, bottom: 20.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            word.word,
                            style: const TextStyle(
                                fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Text(
                            getCardQueueLabel(card?.queue ?? -1),
                            style: const TextStyle(
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
                            Row(
                              children: [
                                Text(
                                  word.mainMeaning,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  word.subMeaning!,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
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
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // 画像検索のセクション
                                      const Text(
                                        '画像検索',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _searchImage(word.word);
                                          },
                                          child: Text('単語'),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _searchImage(word.word);
                                          },
                                          child: Text('例文'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // 辞書を引くのセクション
                                      const Text(
                                        '英和辞書',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _searchDictionary(word.word);
                                          },
                                          child: Text('weblio'),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _searchEnglishDictionary(word.word);
                                          },
                                          child: Text('英次郎'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // 類義語を検索のセクション
                                      const Text(
                                        '英英辞書',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _searchDictionary(word.word);
                                          },
                                          child: Text(
                                            'Cambridge',
                                            style: TextStyle(fontSize: 9),
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          _searchEnglishDictionary(word.word);
                                        },
                                        child: Text('Oxford'),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // 類義語を検索のセクション
                                      const Text(
                                        'その他　',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _searchDictionary(word.word);
                                          },
                                          child: Text('語源'),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _searchEnglishDictionary(word.word);
                                          },
                                          child: Text('類義語'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        '　　　　',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _searchDictionary(word.word);
                                          },
                                          child: Text('コーパス',
                                              style: TextStyle(fontSize: 13)),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _searchEnglishDictionary(word.word);
                                          },
                                          child: Text('天才\n英単語'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
              onPressed: () {
                String? voicePath;

                if (showDetails) {
                  voicePath = word?.sentenceVoice; // 裏面ではsentence_voiceを再生
                } else {
                  voicePath = word?.wordVoice; // 表面ではword_voiceを再生
                }

                _playVoice(voicePath);
              },
              child: Icon(Icons.volume_up),
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
                            Text('未学習'),
                            Text(
                              viewModel.newCardCount.toString(),
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text('覚え中'),
                            Text(
                              viewModel.learningCardCount.toString(),
                              style: TextStyle(fontSize: 20),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text('復習'),
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

  void showSettingsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<DataViewModel>(
          builder: (context, viewModel, child) {
            // モーダル内で新規カードの上限を保持する変数
            return AlertDialog(
              title: Text('新規カード枚数上限'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: '今日だけ',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      // 入力を一時変数に保存
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'ずっと',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      // 入力を一時変数に保存
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('保存'),
                  onPressed: () {
                    // 保存時に viewModel に値を設定し、UI を更新
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
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
