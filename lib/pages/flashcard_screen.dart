import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:kokotan/model/deck_list.dart';
import 'package:kokotan/pages/word_edit_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:kokotan/view_models/data_view_model.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'dart:typed_data';

class FlashCardScreen extends StatefulWidget {
  final int deckID;
  FlashCardScreen(this.deckID, {Key? key})
      : super(key: key); // コンストラクタでdeckIDを受け取る

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
        return Color(0xFF3C8CB4);
      case 1: // 学習中
        return Color(0xFFB43C3C);
      case 2: // 復習
        return Color(0xFF3CB43E);
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
            });
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                  viewModel.deckData[(widget.deckID).toString()]?['deckName']),
              centerTitle: true, // タイトルを中央に配置
              actions: [
                if (viewModel.deckData[(widget.deckID).toString()]![
                        'isDownloaded'] ==
                    DownloadStatus.downloaded)
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
                    if (!showDetails)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 200),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.touch_app,
                                size: 50,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Tap!",
                                style: TextStyle(
                                    fontFamily: 'ZenMaruGothic',
                                    fontWeight: FontWeight.w700, // Bold
                                    fontSize: 20,
                                    color: Color(0xFF333333)),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Visibility(
                        visible: showDetails,
                        child: Padding(
                          padding:
                              const EdgeInsets.only(left: 25.0, right: 25.0),
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
                                    borderRadius: BorderRadius.circular(12),
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
                              SizedBox(
                                height: 10,
                              ),
                              // ここから追加要素
                              if (word.imageUrl != null &&
                                  word.imageUrl!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      File(word.imageUrl!), // !を使う前にnullチェック
                                      width: double.infinity,
                                      fit: BoxFit.cover, // カード全体に収まるように表示
                                      errorBuilder:
                                          (context, error, stackTrace) {
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: double.infinity, // 横幅を最大限に広げる
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey), // 外枠をグレーに
                                          borderRadius:
                                              BorderRadius.circular(12), // 角を丸く
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(
                                              12.0), // 内側の余白を設定
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                word.englishDefinition!,
                                                style: const TextStyle(
                                                  fontFamily: 'ZenMaruGothic',
                                                  fontSize: 16,
                                                  color: Color(0xFF333333),
                                                  fontWeight: FontWeight
                                                      .w600, // テキストの太さを少し太めに
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: -11,
                                        left: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Color.fromARGB(
                                                255, 60, 177, 180),
                                            borderRadius:
                                                BorderRadius.circular(12),
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: double.infinity, // 横幅を最大限に広げる
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey), // 外枠をグレーに
                                          borderRadius:
                                              BorderRadius.circular(12), // 角を丸く
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(
                                              12.0), // 内側の余白を設定
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                word.etymology!,
                                                style: const TextStyle(
                                                  fontFamily: 'ZenMaruGothic',
                                                  fontSize: 16,
                                                  color: Color(0xFF333333),
                                                  fontWeight: FontWeight
                                                      .w600, // テキストの太さを少し太めに
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: -11,
                                        left: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Color.fromARGB(
                                                255, 60, 177, 180),
                                            borderRadius:
                                                BorderRadius.circular(12),
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: double.infinity, // 横幅を最大限に広げる
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey), // 外枠をグレーに
                                          borderRadius:
                                              BorderRadius.circular(12), // 角を丸く
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(
                                              12.0), // 内側の余白を設定
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                word.memo!,
                                                style: const TextStyle(
                                                  fontFamily: 'ZenMaruGothic',
                                                  fontSize: 16,
                                                  color: Color(0xFF333333),
                                                  fontWeight: FontWeight
                                                      .w600, // テキストの太さを少し太めに
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: -11,
                                        left: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Color.fromARGB(
                                                255, 60, 177, 180),
                                            borderRadius:
                                                BorderRadius.circular(12),
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

                                        const SizedBox(
                                            width: 10), // ボタン間にスペースを追加
                                        Expanded(
                                          child: CustomSearchButton(
                                            label: '例文',
                                            onPressed: () {
                                              _searchSentence(
                                                  word.sentence); // クロージャーでラップ
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

                                        const SizedBox(
                                            width: 10), // ボタン間にスペースを追加
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

                                        const SizedBox(
                                            width: 10), // ボタン間にスペースを追加
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

                                        const SizedBox(
                                            width: 10), // ボタン間にスペースを追加
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
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: Row(
              mainAxisAlignment: MainAxisAlignment.end, // 右端に寄せる
              children: [
                // 左端に戻るボタン
                if (!showDetails)
                  FloatingActionButton(
                    heroTag: 'undoButton', // heroTagを設定
                    onPressed: () async {
                      final previousCard =
                          await viewModel.getPreviousCard(); // 非同期処理

                      if (previousCard != null) {
                        await _playVoice(previousCard.word.wordVoice,
                            viewModel); // 非同期処理の完了を待つ
                      } else {
                        print("履歴がありません");
                      }
                      viewModel.notifyListeners(); // 非同期処理後に通知
                    },
                    backgroundColor: Colors.white, // 背景色を変更
                    foregroundColor:
                        const Color.fromARGB(255, 125, 125, 125), // アイコンの色を変更

                    child: Icon(Icons.undo),
                    tooltip: '戻る',
                  ),

                Row(
                  mainAxisSize: MainAxisSize.min, // 内側のボタンを小さくまとめる
                  children: [
                    // 編集ボタン
                    if (showDetails)
                      FloatingActionButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => WordEditScreen(),
                            ),
                          );
                        },
                        backgroundColor: Colors.white, // 背景色を変更
                        foregroundColor: const Color.fromARGB(
                            255, 125, 125, 125), // アイコンの色を変更

                        heroTag: 'edit', // ヒーローアニメーションの重複を避けるためにタグを追加
                        child: Icon(Icons.edit),
                      ),
                    SizedBox(width: 16), // ボタン間のスペース
                    // 音声再生ボタン
                    FloatingActionButton(
                      heroTag: 'volumeButton', // heroTagを設定
                      backgroundColor: Colors.white, // 背景色を変更
                      foregroundColor:
                          const Color.fromARGB(255, 125, 125, 125), // アイコンの色を変更

                      onPressed: () {
                        String? voicePath;

                        if (showDetails) {
                          voicePath =
                              word?.sentenceVoice; // 裏面ではsentence_voiceを再生
                        } else {
                          voicePath = word?.wordVoice; // 表面ではword_voiceを再生
                        }

                        _playVoice(voicePath, viewModel);
                      },
                      child: Icon(Icons.volume_up),
                    ),
                    SizedBox(width: 16),
                  ],
                ),
              ],
            ),
            bottomNavigationBar: showDetails
                ? BottomAppBar(
                    padding: EdgeInsets.symmetric(vertical: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        _buildCustomButton(
                          context,
                          1,
                          'assets/images/oboenaosu.png',
                          Color(0xFFB61C1C),
                          viewModel,
                        ),
                        _buildCustomButton(
                          context,
                          2,
                          'assets/images/bimyou.png',
                          Color.fromARGB(255, 40, 113, 114),
                          viewModel,
                        ),
                        _buildCustomButton(
                          context,
                          3,
                          'assets/images/OK.png',
                          Color.fromARGB(255, 52, 150, 153),
                          viewModel,
                        ),
                        _buildCustomButton(
                          context,
                          4,
                          'assets/images/yoyuu.png',
                          Color.fromARGB(255, 60, 176, 180),
                          viewModel,
                        ),
                      ],
                    ),
                  )
                : BottomAppBar(
                    color: Colors.white, // 背景色を設定
                    padding: EdgeInsets.symmetric(vertical: 3),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                '新規',
                                style: TextStyle(
                                    fontFamily: 'ZenMaruGothic',
                                    fontWeight: FontWeight.w500, // Bold
                                    fontSize: 16,
                                    color: Color(0xFF333333)),
                              ),
                              Text(
                                viewModel
                                    .newCardCountByDeckID(widget.deckID)
                                    .toString(),
                                style: TextStyle(
                                    fontFamily: 'ZenMaruGothic',
                                    fontWeight: FontWeight.w700, // Bold
                                    fontSize: 24,
                                    color: Color(0xFF333333)),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '学習中',
                                style: TextStyle(
                                    fontFamily: 'ZenMaruGothic',
                                    fontWeight: FontWeight.w500, // Bold
                                    fontSize: 16,
                                    color: Color(0xFF333333)),
                              ),
                              Text(
                                viewModel
                                    .learningCardCountByDeckID(widget.deckID)
                                    .toString(),
                                style: TextStyle(
                                    fontFamily: 'ZenMaruGothic',
                                    fontWeight: FontWeight.w700, // Bold
                                    fontSize: 24,
                                    color: Color(0xFF333333)),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '復習',
                                style: TextStyle(
                                    fontFamily: 'ZenMaruGothic',
                                    fontWeight: FontWeight.w500, // Bold
                                    fontSize: 16,
                                    color: Color(0xFF333333)),
                              ),
                              Text(
                                viewModel
                                    .reviewCardCountByDeckID(widget.deckID)
                                    .toString(),
                                style: TextStyle(
                                    fontFamily: 'ZenMaruGothic',
                                    fontWeight: FontWeight.w700, // Bold
                                    fontSize: 24,
                                    color: Color(0xFF333333)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Future<void> showSettingsModal(BuildContext context) async {
    // ViewModelから現在のカード枚数を取得
    final viewModel = Provider.of<DataViewModel>(context, listen: false);

    // テキストコントローラに現在の設定を反映
    final newCardLimitController = TextEditingController(
        text: viewModel.deckData[(widget.deckID).toString()]!['newPerDayLimit']
            .toString());

    final reviewCardLimitController = TextEditingController(
        text: viewModel.deckData[(widget.deckID).toString()]!['newPerDayLimit']
            .toString());

    await showDialog(
      context: context,
      builder: (context) {
        return Consumer<DataViewModel>(
          builder: (context, viewModel, child) {
            return StatefulBuilder(
              builder: (context, setState) {
                // デフォルト値を設定
                newCardLimitController.text = viewModel
                    .deckData[(widget.deckID).toString()]!['newPerDayLimit']
                    .toString();
                reviewCardLimitController.text = viewModel
                    .deckData[(widget.deckID).toString()]!['reviewPerDayLimit']
                    .toString();
                return AlertDialog(
                  title: const Text(
                    '1日にできるカードの上限',
                    style: TextStyle(
                        fontFamily: 'ZenMaruGothic',
                        fontWeight: FontWeight.w700, // Bold
                        fontSize: 20,
                        color: Color(0xFF333333)),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 今日だけの新規カード設定（横並び）
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '新規カード',
                              style: TextStyle(
                                  fontFamily: 'ZenMaruGothic',
                                  fontWeight: FontWeight.w700, // Bold
                                  fontSize: 20,
                                  color: Color(0xFF333333)),
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
                          const Text(
                            '枚',
                            style: TextStyle(
                                fontFamily: 'ZenMaruGothic',
                                fontWeight: FontWeight.w700, // Bold
                                fontSize: 20,
                                color: Color(0xFF333333)),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
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
                          const Text(
                            '枚',
                            style: TextStyle(
                                fontFamily: 'ZenMaruGothic',
                                fontWeight: FontWeight.w700, // Bold
                                fontSize: 20,
                                color: Color(0xFF333333)),
                          ),
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
                      child: const Text(
                        'キャンセル',
                        style: TextStyle(
                            fontFamily: 'ZenMaruGothic',
                            fontWeight: FontWeight.w700, // Bold
                            fontSize: 20,
                            color: Color(0xFF333333)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: const Text(
                        '保存',
                        style: TextStyle(
                            fontFamily: 'ZenMaruGothic',
                            fontWeight: FontWeight.w700, // Bold
                            fontSize: 20,
                            color: Color(0xFF333333)),
                      ),
                      onPressed: () async {
                        int? newCardLimit;
                        int? reviewCardLimit;

                        // 新規カードの上限値を取得
                        newCardLimit =
                            int.tryParse(newCardLimitController.text) ?? 20;

                        // 復習カードの上限値を取得
                        reviewCardLimit =
                            int.tryParse(reviewCardLimitController.text) ?? 200;

                        // 設定を更新
                        await viewModel.updateCardSettings(
                            newCardLimit: newCardLimit,
                            reviewCardLimit: reviewCardLimit,
                            deckID: widget.deckID);

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

  Widget _buildCustomButton(BuildContext context, int ease, String imagePath,
      Color color, DataViewModel viewModel) {
    // easeをlabelに変換
    String label = _getLabelFromEase(ease);

    // cardProperties を取得
    Map<String, dynamic>? cardProperties = viewModel.prepareCardAnswer(ease);

    //ボタンに表示する日数
    String ivlText = viewModel.calculateTimeUntilNextReview(
        viewModel.currentCard!, cardProperties!, ease);

    return Expanded(
      // ボタンの幅を均等にする
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0), // 左右に少し隙間を追加
        child: ElevatedButton(
          onPressed: () async {
            if (cardProperties != null) {
              await viewModel.answerCard(
                  cardProperties, ease, context, widget.deckID);
            }
            setState(() {
              showDetails = false;
            });

            final newWord = viewModel.currentCard?.word;
            if (newWord != null) {
              _playVoice(newWord.wordVoice, viewModel);
            }
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14), // 角を少し丸める
            ),
            elevation: 3, // 影を追加
            padding: const EdgeInsets.symmetric(vertical: 0), // ボタンの内側の余白
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'ZenMaruGothic',
                  fontWeight: FontWeight.w700, // Bold
                  fontSize: 20,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 0), // シャドウの位置
                      blurRadius: 4.0, // ぼかしの範囲
                      color: Colors.black.withOpacity(0.5), // シャドウの色
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$ivlText', // 計算されたテキストを表示
                style: TextStyle(
                  fontFamily: 'ZenMaruGothic',
                  fontWeight: FontWeight.w500, // Bold
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 0), // シャドウの位置
                      blurRadius: 4.0, // ぼかしの範囲
                      color: Colors.black.withOpacity(0.5), // シャドウの色
                    ),
                  ],
                ),
              ),
              // const SizedBox(height: 2),
              // Image.asset(
              //   imagePath,
              //   width: 40,
              //   height: 40,
              // ),
            ],
          ),
        ),
      ),
    );
  }

  // easeの値をlabelに変換する関数
  String _getLabelFromEase(int ease) {
    switch (ease) {
      case 1:
        return '覚え直す';
      case 2:
        return '　微妙　';
      case 3:
        return '　OK　';
      case 4:
        return '　余裕　';
      default:
        return '覚え直す'; // デフォルトは覚え直す
    }
  }

  //URL集
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
    final _url = Uri.parse('https://www.etymonline.com/jp/word/$keyword');
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

  Future<void> _reportError() async {
    const url =
        'https://docs.google.com/forms/d/e/1FAIpQLSeXGO79qrbByjJU0adealF6E_m18NcrXgHFl5FKbOnnpbS-Ng/viewform'; // 飛びたいURLを指定
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // int _getEaseValue(String label) {
  //   switch (label) {
  //     case '覚え直す':
  //       return 1;
  //     case '微妙':
  //       return 2;
  //     case 'OK':
  //       return 3;
  //     case '余裕':
  //       return 4;
  //     default:
  //       return 1;
  //   }
  // }

  // Widget _buildButton(BuildContext context, String label, Color color,
  //     DataViewModel viewModel) {
  //   return ElevatedButton(
  //     onPressed: () async {
  //       int ease = _getEaseValue(label);
  //       await viewModel.answerCard(ease, context);
  //       setState(() {
  //         showDetails = false;
  //       });
  //       // 新しいカードのword_voiceを再生
  //       final newWord = viewModel.currentCard?.word;
  //       if (newWord != null) {
  //         _playVoice(newWord.wordVoice);
  //       }
  //     },
  //     style: ElevatedButton.styleFrom(
  //       foregroundColor: Colors.white,
  //       backgroundColor: color,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //       elevation: 0,
  //       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  //     ),
  //     child: Text(label),
  //   );
  // }
}

class CustomSearchButton extends StatelessWidget {
  final String label;
  final Function onPressed;

  CustomSearchButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onPressed(),
      style: ElevatedButton.styleFrom(
        foregroundColor: Color(0xFF464646),
        backgroundColor: Color(0xFFE9E9E9),
        // ignore: prefer_const_constructors
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        textStyle: TextStyle(
          fontFamily: 'ZenMaruGothic', // フォントファミリーを指定
          fontWeight: FontWeight.w700, // フォントウェイト
          fontSize: 16, // フォントサイズ
        ),
        minimumSize: Size(double.infinity, 10), // 高さを調整
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // 角を丸く
        ),
      ),
      child: Text(label),
    );
  }
}
