import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:kokotan/pages/word_edit_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:kokotan/view_models/data_view_model.dart';

class FlashCardScreen extends StatefulWidget {
  @override
  _FlashCardScreenState createState() => _FlashCardScreenState();
}

class _FlashCardScreenState extends State<FlashCardScreen> {
  bool showDetails = false; // 詳細を表示するかどうかのフラグ
  TextEditingController field = TextEditingController();
  bool haspasted = false;
  AudioPlayer _audioPlayer = AudioPlayer();



  String getCardQueueLabel(int queue) {
    switch (queue) {
      case 0:
        return "新規";
      case 1:
        return "学習中";
      case 2:
        return "復習";
      default:
        return "Unknown";
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
  void initState() {
    super.initState();
    // 初回表示時にwordVoiceを再生
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final word =
          Provider.of<DataViewModel>(context, listen: false).currentCard?.word;
      if (word != null) {
        _playVoice(word.wordVoice); // 表面の音声を再生
      }
    });
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
              showDetails = true;
              _playVoice(word?.sentenceVoice); // 裏面が表示されたらsentence_voiceを再生
            });
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text('Flash Card'),
              // actions: <Widget>[
              //   IconButton(
              //     icon: Icon(Icons.settings),
              //     onPressed: () {
              //       showSettingsModal(context);
              //     },
              //   ),
              // ],
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
                            Wrap(
                              children: [
                                Text(
                                  word.mainMeaning,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900),
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                ),
                                Text(
                                  word.subMeaning!,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500),
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
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
                                            _searchSentence(word.sentence);
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
                                            _searchWeblio(word.word);
                                          },
                                          child: Text('weblio'),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _searchEijiro(word.word);
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
                                            _searchCambidge(word.word);
                                          },
                                          child: const Text(
                                            'Cambridge',
                                            style: TextStyle(fontSize: 9),
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          _searchOxford(word.word);
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
                                            _searchGogen(word.word);
                                          },
                                          child: Text('語源'),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _searchThesaurus(word.word);
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
                                            _searchSkell(word.word);
                                          },
                                          child: Text('コーパス',
                                              style: TextStyle(fontSize: 13)),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _searchTensai(word.word);
                                          },
                                          child: Text('天才\n英単語'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // DropRegion(
                            //   onDropOver: (event) => DropOperation.move,
                            //   formats: Formats.standardFormats,
                            //   onPerformDrop: (event) async {
                            //     final item = event.session.items.first;
                            //     final reader = item.dataReader!;
                            //     if (reader.canProvide(Formats.jpeg)) {
                            //       reader.getFile(Formats.jpeg, (file) {
                            //         file.readAll().then((data) {
                            //           setState(() {
                            //             _imageData = data;
                            //           });
                            //         });
                            //       }, onError: (error) {
                            //         print('Error reading image: $error');
                            //       });
                            //     }
                            //   },
                            //   child: _imageData == null
                            //       ? Container(
                            //           padding: EdgeInsets.all(20),
                            //           decoration: BoxDecoration(
                            //             border: Border.all(
                            //                 color: Colors.blue, width: 2),
                            //             borderRadius: BorderRadius.circular(8),
                            //           ),
                            //           child: Column(
                            //             mainAxisSize: MainAxisSize.min,
                            //             children: <Widget>[
                            //               Image.asset(
                            //                   'assets/images/add-picture.png',
                            //                   width: 50,
                            //                   height: 50),
                            //               Text('ここに画像をドロップ！',
                            //                   style: TextStyle(fontSize: 16)),
                            //             ],
                            //           ),
                            //         )
                            //       : Image.memory(_imageData!),
                            // ),
                            // SizedBox(height: 20),
                            // if (haspasted)
                            //   Container(
                            //     width: double.infinity,
                            //     padding: EdgeInsets.all(15),
                            //     decoration: BoxDecoration(
                            //       color:
                            //           Color.fromARGB(255, 254, 254, 244), // 背景色
                            //       border: Border.all(
                            //           color: Color.fromARGB(255, 248, 210, 154),
                            //           width: 2), // 枠線
                            //       borderRadius: BorderRadius.circular(8), // 角丸
                            //     ),
                            //     child: Text(
                            //       '${field.text}',
                            //       style: TextStyle(
                            //           fontSize: 16,
                            //           fontWeight: FontWeight.bold),
                            //     ),
                            //   ),
                            // SizedBox(height: 20),
                            // ElevatedButton.icon(
                            //   icon: Icon(Icons.paste, color: Colors.white),
                            //   onPressed: pasteFromClipboard,
                            //   label: Text(
                            //     'ペースト',
                            //     style: TextStyle(
                            //       fontSize: 18,
                            //       color: Colors.white,
                            //     ),
                            //   ),
                            //   style: ElevatedButton.styleFrom(
                            //     backgroundColor:
                            //         Color.fromARGB(255, 127, 127, 127),
                            //     padding: EdgeInsets.symmetric(
                            //         horizontal: 20, vertical: 10),
                            //   ),
                            // ),
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
                    padding: EdgeInsets.symmetric(vertical: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        _buildCustomButton(
                          context,
                          '覚え直す',
                          'assets/images/oboenaosu.png',
                          Color.fromARGB(255, 255, 91, 91),
                          viewModel,
                        ),
                        _buildCustomButton(
                          context,
                          '微妙',
                          'assets/images/bimyou.png',
                          Color.fromARGB(255, 111, 243, 197),
                          viewModel,
                        ),
                        _buildCustomButton(
                          context,
                          'OK',
                          'assets/images/OK.png',
                          Color.fromARGB(255, 83, 209, 161),
                          viewModel,
                        ),
                        _buildCustomButton(
                          context,
                          '余裕',
                          'assets/images/yoyuu.png',
                          Color.fromARGB(255, 33, 176, 175),
                          viewModel,
                        ),
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
            return StatefulBuilder(
              builder: (context, setState) {
                // デフォルト値を設定 (tempがあればtempの値を優先)
                newCardLimitController.text = viewModel.newCardLimit.toString();
                reviewCardLimitController.text =
                    viewModel.reviewCardLimit.toString();
            return AlertDialog(
                  title: const Text('1日にできるカードの上限'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                      // 今日だけの新規カード設定（横並び）
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '新規カード',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                          SizedBox(
                            width: 80, // テキストフィールドの幅を調整
                            child: TextField(
                              controller: newCardLimitController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right, // テキストを右寄せ
                    decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 8),
                                border: OutlineInputBorder(), // ボーダーを追加
                                hintText: '入力',
                    ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('枚', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      //sizebox

                      // // チェックボックス（新規カード）
                      // CheckboxListTile(
                      //   contentPadding: EdgeInsets.zero, // コンテンツのパディングを調整
                      //   title: const Text(
                      //     '   今日だけこの設定を使う',
                      //     style: TextStyle(fontSize: 14), // テキストサイズを小さく
                      //     overflow: TextOverflow.ellipsis, // テキストを1行に収める
                      //   ),
                      //   value: viewModel
                      //       .isNewCardTempLimit, // SharedPreferences から読み込んだ値
                      //   onChanged: (bool? value) {
                      //     setState(() {
                      //       viewModel.isNewCardTempLimit = value ?? false;
                      //     });
                      //   },
                      // ),
                      // SizedBox(
                      //   height: 10,
                      // ),
                      // 今日だけの復習カード設定（横並び）
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '復習カード',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                          SizedBox(
                            width: 80, // テキストフィールドの幅を調整
                            child: TextField(
                              controller: reviewCardLimitController,
                    keyboardType: TextInputType.number,
                              textAlign: TextAlign.right, // テキストを右寄せ
                              decoration: InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 8),
                                border: OutlineInputBorder(), // ボーダーを追加
                                hintText: '入力',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('枚', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                      // // チェックボックス（復習カード）
                      // CheckboxListTile(
                      //   contentPadding: EdgeInsets.zero, // コンテンツのパディングを調整
                      //   title: const Text(
                      //     '   今日だけこの設定を使う',
                      //     style: TextStyle(fontSize: 14), // テキストサイズを小さく
                      //     overflow: TextOverflow.ellipsis, // テキストを1行に収める
                      //   ),
                      //   value: viewModel
                      //       .isReviewCardTempLimit, // SharedPreferences から読み込んだ値
                      //   onChanged: (bool? value) {
                      //     setState(() {
                      //       viewModel.isReviewCardTempLimit = value ?? false;
                      //     });
                      //   },
                      // ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                      child: const Text('キャンセル'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                      child: const Text('保存'),
                      onPressed: () async {
                        int? newCardLimitPermanent;
                        int? reviewCardLimitPermanent;

                        // 新規カードの上限値を取得
                        newCardLimitPermanent =
                            int.tryParse(newCardLimitController.text) ??
                                viewModel.getNewCardLimit();

// 復習カードの上限値を取得
                        reviewCardLimitPermanent =
                            int.tryParse(reviewCardLimitController.text) ??
                                viewModel.getReviewCardLimit();

                        // 設定を更新
                        await viewModel.updateCardSettings(
                          newCardLimitPermanent: newCardLimitPermanent,
                          reviewCardLimitPermanent: reviewCardLimitPermanent,
                        );

                        Navigator.pop(context); // ダイアログを閉じる
                  },
                ),
              ],
                );
              },
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

  void _searchSentence(String keyword) async {
    final _url = Uri.parse('https://www.google.com/search?tbm=isch&q=$keyword');
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_url');
    }
  }

  void _searchWeblio(String keyword) async {
    final _url = Uri.parse('https://www.weblio.jp/content/$keyword');
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_url');
    }
  }

  void _searchEijiro(String keyword) async {
    final _url = Uri.parse('https://eow.alc.co.jp/$keyword');
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_url');
    }
  }

  void _searchCambidge(String keyword) async {
    final _url = Uri.parse(
        'https://dictionary.cambridge.org/dictionary/english/$keyword');
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_url');
    }
  }

  void _searchOxford(String keyword) async {
    final _url = Uri.parse(
        'https://www.oxfordlearnersdictionaries.com/definition/english/$keyword');
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_url');
    }
  }

  void _searchSkell(String keyword) async {
    final _url = Uri.parse(
        'https://skell.sketchengine.eu/#result?f=thesaurus&lang=en&query=$keyword');
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_url');
    }
  }

  void _searchThesaurus(String keyword) async {
    final _url = Uri.parse('https://www.thesaurus.com/browse/$keyword');
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_url');
    }
  }

  void _searchGogen(String keyword) async {
    final _url = Uri.parse('https://www.etymonline.com/word/$keyword');
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_url');
    }
  }

  void _searchTensai(String keyword) async {
    final _url = Uri.parse('https://www.tentan.jp/word/$keyword');
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

  Widget _buildCustomButton(BuildContext context, String label,
      String imagePath, Color color, DataViewModel viewModel) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () async {
          int ease = _getEaseValue(label);
          await viewModel.answerCard(ease, context);
          setState(() {
            showDetails = false;
          });
          // 新しいカードのword_voiceを再生
          final newWord = viewModel.currentCard?.word;
          if (newWord != null) {
            _playVoice(newWord.wordVoice);
          }
        },
        style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: color,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // 角丸なし
            ),
            elevation: 0,
            padding: EdgeInsets.zero),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 60, // アイコンのサイズ
              height: 40,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String label, Color color,
      DataViewModel viewModel) {
    return ElevatedButton(
      onPressed: () async {
        int ease = _getEaseValue(label);
        await viewModel.answerCard(ease, context);
        setState(() {
          showDetails = false;
        });
        // 新しいカードのword_voiceを再生
        final newWord = viewModel.currentCard?.word;
        if (newWord != null) {
          _playVoice(newWord.wordVoice);
        }
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
      case '覚え直す':
        return 1;
      case '微妙':
        return 2;
      case 'OK':
        return 3;
      case '余裕':
        return 4;
      default:
        return 1;
    }
  }
}
