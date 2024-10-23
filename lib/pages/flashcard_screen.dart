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
  Future<void> _playVoice(String? voicePath, DataViewModel viewModel) async {
    if (voicePath != null && voicePath.isNotEmpty) {
      final file = File(voicePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        print('Playing file from path: $voicePath, size: $fileSize bytes');
        try {
          await _audioPlayer.stop(); // 再生前に停止
          await _audioPlayer.dispose(); // プレイヤーを完全にリセット
          _audioPlayer = AudioPlayer(); // 新しいインスタンスを作成
          await _audioPlayer.play(DeviceFileSource(voicePath)); // ファイルを再生
        } catch (e) {
          print('Error playing audio: $e');
        }
      } else {
        print('File not found at path: $voicePath');
        await viewModel.reDownloadAndImportExcel();
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
      final viewModel =
          Provider.of<DataViewModel>(context, listen: false); // ここでviewModelを取得
      final word = viewModel.currentCard?.word;
      if (word != null) {
        _playVoice(word.wordVoice, viewModel); // 表面の音声を再生
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
              _playVoice(word?.sentenceVoice, viewModel); // viewModelを渡す
              // viewModel.addCardToHistory(viewModel.currentCard!); // 履歴にカードを追加
            });
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text('スタンダードA'),
              centerTitle: true, // タイトルを中央に配置
              actions: [
                if (Provider.of<DataViewModel>(context, listen: true)
                    .isAllDataDownloaded)
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => showSettingsModal(context), // ダイアログを表示
                  ),
                IconButton(
                  icon: const Icon(Icons.help_outline), // ヘルプアイコンを残す
                  onPressed: launchHelpURL,
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
                          EdgeInsets.only(top: 8.0, left: 25.0, bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline:
                            TextBaseline.alphabetic, // アルファベットのベースラインで揃える
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            word.word,
                            style: TextStyle(
                                fontFamily: 'ZenMaruGothic',
                                fontWeight: FontWeight.w700, // Bold
                                fontSize: 40,
                                color: Color(0xFF333333)),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Text(
                            getCardQueueLabel(card?.queue ?? -1),
                            style: TextStyle(
                              fontFamily: 'ZenMaruGothic',
                              fontWeight: FontWeight.w400, // Bold
                              fontSize: 20,
                              color: getCardQueueColor(card?.queue ?? -1),
                            ),
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
                                    fontFamily: 'ZenMaruGothic',
                                    fontWeight: FontWeight.w700, // Bold
                                    fontSize: 22,
                                    color: Colors.red,
                                  ),
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                ),
                                Text(
                                  word.subMeaning ?? '',
                                  style: const TextStyle(
                                      fontFamily: 'ZenMaruGothic',
                                      fontWeight: FontWeight.w500, // Bold
                                      fontSize: 22,
                                      color: Color(0xFF333333)),
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                ),
                              ],
                            ),
                            SizedBox(height: 14),
                            Container(
                                width: double.infinity, // 横幅を最大限に広げる
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        word.sentence,
                                  style: TextStyle(
                                            fontFamily: 'ZenMaruGothic',
                                            fontWeight:
                                                FontWeight.w500, // 英語を太字に
                                            fontSize: 21,
                                            color: Color(0xFF333333)),
                                      ),
                                      const SizedBox(
                                        height: 8,
                                      ),
                                      Text(
                                        word.sentenceJp,
                                        style: TextStyle(
                                            fontFamily: 'ZenMaruGothic',
                                            fontWeight:
                                                FontWeight.w400, // 日本語は通常の太さ
                                            fontSize: 18,
                                            color: Color(0xFF333333)),
                                ),
                                    ],
                                  ),
                                )),
                            // ここから追加要素
                            if (word.imageUrl != null &&
                                word.imageUrl!.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(word.imageUrl!), // !を使う前にnullチェック
                                    width: double.infinity,
                                    fit: BoxFit.cover, // カード全体に収まるように表示
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Text(
                                          '画像を表示できません',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                            if (word.englishDefinition != null &&
                                word.englishDefinition!.isNotEmpty)
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Text(
                                          word.englishDefinition!,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF333333),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: -8,
                                      left: -8,
                                      child: Container(
                              padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          '英英',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            if (word.etymology != null &&
                                word.etymology!.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                children: [
                                    Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Text(
                                          word.etymology!,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF333333),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: -8,
                                      left: -8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          '語源',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                      ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            if (word.memo != null && word.memo!.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Text(
                                          word.memo!,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF333333),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: -8,
                                      left: -8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blueAccent,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'メモ',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ),
                            const SizedBox(
                              height: 20,
                            ),
                            Divider(
                              color: Colors.grey, // 線の色
                              thickness: 1, // 線の太さ
                              indent: 10, // 左側の余白
                              endIndent: 10, // 右側の余白
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 15.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                  // 画像検索のセクション
                                      const Text(
                                    '画像検索',
                                    style: const TextStyle(
                                        fontFamily: 'ZenMaruGothic',
                                        fontWeight: FontWeight.w500, // Bold
                                            fontSize: 18,
                                        color: Color(0xFF333333)),
                                      ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: CustomSearchButton(
                                          label: '単語',
                                          onPressed: () {
                                            _searchImage(
                                                word.word); // クロージャーでラップ
                                          },
                                        ),
                                        ),

                                      const SizedBox(width: 10), // ボタン間にスペースを追加
                                      Expanded(
                                        child: CustomSearchButton(
                                          label: '例文',
                                          onPressed: () {
                                            _searchSentence(
                                                word.word); // クロージャーでラップ
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // // 辞書を引くのセクション
                                  // const Text(
                                  //   '英和辞書',
                                  //   style: const TextStyle(
                                  //     fontFamily: 'ZenMaruGothic',
                                  //     fontWeight: FontWeight.w500, // Bold
                                  //     fontSize: 18,
                                  //   ),
                                  // ),
                                  // Row(
                                  //   mainAxisAlignment:
                                  //       MainAxisAlignment.spaceBetween,
                                  //   children: [
                                  //     Expanded(
                                  //       child: CustomSearchButton(
                                  //         label: 'weblio',
                                  //         color: Colors.red,
                                  //         onPressed: () {
                                  //           _searchWeblio(
                                  //               word.word); // クロージャーでラップ
                                  //         },
                                  //       ),
                                  //     ),

                                  //     const SizedBox(width: 10), // ボタン間にスペースを追加
                                  //     Expanded(
                                  //       child: CustomSearchButton(
                                  //         label: '英辞郎',
                                  //         color: Colors.red,
                                  //         onPressed: () {
                                  //           _searchEijiro(
                                  //               word.word); // クロージャーでラップ
                                  //         },
                                  //       ),
                                  //     ),
                                  //   ],
                                  // ),
                                  // const SizedBox(height: 10),

                                      // 類義語を検索のセクション
                                      const Text(
                                        '英英辞書',
                                    style: const TextStyle(
                                        fontFamily: 'ZenMaruGothic',
                                        fontWeight: FontWeight.w500, // Bold
                                            fontSize: 18,
                                        color: Color(0xFF333333)),
                                      ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: CustomSearchButton(
                                          label: 'Cambridge',
                                          onPressed: () {
                                            _searchCambidge(
                                                word.word); // クロージャーでラップ
                                          },
                                        ),
                                      ),

                                      const SizedBox(width: 10), // ボタン間にスペースを追加
                                      Expanded(
                                        child: CustomSearchButton(
                                          label: 'Oxford',
                                        onPressed: () {
                                            _searchOxford(
                                                word.word); // クロージャーでラップ
                                        },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // その他セクション
                                  const Text(
                                    'その他',
                                    style: const TextStyle(
                                        fontFamily: 'ZenMaruGothic',
                                        fontWeight: FontWeight.w500, // Bold
                                        fontSize: 18,
                                        color: Color(0xFF333333)),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: CustomSearchButton(
                                          label: '語源',
                                          onPressed: () {
                                            _searchGogen(
                                                word.word); // クロージャーでラップ
                                          },
                                        ),
                                        ),

                                      const SizedBox(width: 10), // ボタン間にスペースを追加
                                      Expanded(
                                        child: CustomSearchButton(
                                          label: '類義語',
                                          onPressed: () {
                                            _searchThesaurus(
                                                word.word); // クロージャーでラップ
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // その他の検索セクション
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: CustomSearchButton(
                                          label: 'コーパス',
                                          onPressed: () {
                                            _searchSkell(
                                                word.word); // クロージャーでラップ
                                          },
                                        ),
                                        ),

                                      const SizedBox(width: 10), // ボタン間にスペースを追加
                                      Expanded(
                                        child: CustomSearchButton(
                                          label: '天才英単語',
                                          onPressed: () {
                                            _searchTensai(
                                                word.word); // クロージャーでラップ
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20), // ボタン間にスペースを追加

                            Align(
                              alignment: Alignment.bottomLeft, // 左下に配置
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: InkWell(
                                  onTap: _reportError, // タップ時にURLを開く
                                  child: Text(
                                    '間違いを報告する',
                                    style: const TextStyle(
                                        fontFamily: 'ZenMaruGothic',
                                        fontWeight: FontWeight.w500, // Bold
                                        fontSize: 18,
                                        color: Colors.blue),
                                  ),
                                ),
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
