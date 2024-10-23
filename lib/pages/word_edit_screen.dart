import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // 画像ピッカー用
import 'dart:io'; // 画像ファイル操作用
import 'package:flutter_image_compress/flutter_image_compress.dart'; // 画像圧縮用
import 'package:flutter/services.dart'; // クリップボード用
import 'package:kokotan/view_models/data_view_model.dart';

class WordEditScreen extends StatefulWidget {
  @override
  _WordEditScreenState createState() => _WordEditScreenState();
}

class _WordEditScreenState extends State<WordEditScreen> {
  late TextEditingController wordController;
  late TextEditingController pronunciationController;
  late TextEditingController mainMeaningController;
  late TextEditingController subMeaningController;
  late TextEditingController sentenceController;
  late TextEditingController sentenceJpController;

  // 新しいコントローラ
  late TextEditingController englishDefinitionController;
  late TextEditingController etymologyController;
  late TextEditingController memoController;

  File? _selectedImage; // 選択された画像ファイル
  bool _isImageDeleted = false; // 画像を削除したかどうかを示すフラグ

  @override
  void initState() {
    super.initState();

    final viewModel = Provider.of<DataViewModel>(context, listen: false);
    final currentWord = viewModel.currentWord;

    wordController = TextEditingController(text: currentWord?.word ?? '');
    pronunciationController =
        TextEditingController(text: currentWord?.pronunciation ?? '');
    mainMeaningController =
        TextEditingController(text: currentWord?.mainMeaning ?? '');
    subMeaningController =
        TextEditingController(text: currentWord?.subMeaning ?? '');
    sentenceController =
        TextEditingController(text: currentWord?.sentence ?? '');
    sentenceJpController =
        TextEditingController(text: currentWord?.sentenceJp ?? '');

    // 新しいコントローラの初期化
    englishDefinitionController =
        TextEditingController(text: currentWord?.englishDefinition ?? '');
    etymologyController =
        TextEditingController(text: currentWord?.etymology ?? '');
    memoController = TextEditingController(text: currentWord?.memo ?? '');

    // 画像がすでに保存されている場合、そのパスを使用して表示
    if (currentWord?.imageUrl != null && currentWord!.imageUrl!.isNotEmpty) {
      _selectedImage = File(currentWord.imageUrl!); // 画像パスをFileに変換
    }
  }

  @override
  void dispose() {
    wordController.dispose();
    pronunciationController.dispose();
    mainMeaningController.dispose();
    subMeaningController.dispose();
    sentenceController.dispose();
    sentenceJpController.dispose();

    // 新しいコントローラも解放
    englishDefinitionController.dispose();
    etymologyController.dispose();
    memoController.dispose();

    super.dispose();
  }

  // 画像をアルバムから選択し、圧縮
  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      // 画像を圧縮 (最大サイズを指定)
      final compressedImage = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        '${imageFile.parent.path}/compressed_${imageFile.uri.pathSegments.last}',
        quality: 70, // 画質を70%に
        minWidth: 1080, // 最大横幅を1080に制限
        minHeight: 1080, // 最大縦幅を1080に制限
      );

      setState(() {
        _selectedImage = compressedImage; // 圧縮された画像を使用
      });
    }
  }

  // 画像を削除する
  void _removeImage() {
    setState(() {
      _isImageDeleted = true; // 画像削除フラグを立てる

      _selectedImage = null; // 画像を削除
    });
  }

  // テキストフィールドにペーストボタンを追加するメソッド
  Widget _buildTextFieldWithPaste(
      String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Stack(
        children: [
          TextField(
            controller: controller,
            maxLines: null, // 改行が可能
            decoration: InputDecoration(
              labelText: label,
              suffixIcon: controller.text.isEmpty
                  ? IconButton(
                      icon: Icon(Icons.paste),
                      onPressed: () async {
                        ClipboardData? data =
                            await Clipboard.getData(Clipboard.kTextPlain);
                        if (data != null) {
                          setState(() {
                            controller.text = data.text!;
                          });
                        }
                      },
                    )
                  : null,
            ),
            onChanged: (text) {
              setState(() {}); // 状態を更新してアイコンを表示・非表示に
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DataViewModel>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('カード編集'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: launchHelpURL,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 25.0, right: 25.0),
        child: ListView(
          children: [
            // 単語情報（変更不可）
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 単語表示
                Text(
                  wordController.text, // 単語
                  style: TextStyle(
                      fontFamily: 'ZenMaruGothic',
                      fontWeight: FontWeight.w700, // Bold
                      fontSize: 40,
                      color: Color(0xFF333333)),
                ),
                SizedBox(height: 10),

                // メイン訳とサブ訳を表示
                Wrap(
                  children: [
                    Text(
                      mainMeaningController.text, // メイン訳
                      style: const TextStyle(
                        fontFamily: 'ZenMaruGothic',
                        fontWeight: FontWeight.w700, // Bold
                        fontSize: 22,
                        color: Colors.red,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                    if (subMeaningController.text.isNotEmpty) ...[
                      SizedBox(width: 5),
                      Text(
                        subMeaningController.text, // サブ訳
                        style: const TextStyle(
                            fontFamily: 'ZenMaruGothic',
                            fontWeight: FontWeight.w500, // Bold
                            fontSize: 22,
                            color: Color(0xFF333333)),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ],
                ),

                SizedBox(height: 15),

                // 例文と例文和訳を表示するコンテナ
                Container(
                    width: double.infinity, // 横幅を最大限に広げる
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sentenceController.text,
                            style: TextStyle(
                                fontFamily: 'ZenMaruGothic',
                                fontWeight: FontWeight.w500, // 英語を太字に
                                fontSize: 21,
                                color: Color(0xFF333333)),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            sentenceJpController.text,
                            style: TextStyle(
                                fontFamily: 'ZenMaruGothic',
                                fontWeight: FontWeight.w400, // 日本語は通常の太さ
                                fontSize: 18,
                                color: Color(0xFF333333)),
                          ),
                        ],
                      ),
                    )),

                // スペースの調整
                SizedBox(height: 20),
              ],
            ),

            // 画像表示エリア
            SizedBox(height: 16),
            GestureDetector(
              onTap: () => _pickImageFromGallery(),
              child: Container(
                height: _selectedImage == null ? 100 : null, // 最初は小さめ
                width: double.infinity,
                decoration: BoxDecoration(
                  border: _selectedImage != null
                      ? null
                      : Border.all(color: Colors.grey), // 画像が選択されたら枠を消す
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          Image.file(
                            _selectedImage!,
                            fit: BoxFit.contain, // 画像の全体が表示される
                            width: double.infinity,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: _removeImage, // 削除ボタンを押したら画像を削除
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt,
                                size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              "タップ or ドロップ で画像追加！",
                              style: TextStyle(
                                  fontFamily: 'ZenMaruGothic',
                                  fontWeight: FontWeight.w500, // Bold
                                  fontSize: 16,
                                  color: Color(0xFF333333)),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            SizedBox(height: 16),

            // 英英、語源、メモのフィールド（編集可）
            _buildTextFieldWithPaste('英英', englishDefinitionController),
            _buildTextFieldWithPaste('語源', etymologyController),
            _buildTextFieldWithPaste('その他なんでもメモ', memoController),
            SizedBox(height: 70),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(15.0),
        child: SizedBox(
          width: double.infinity, // 幅を画面いっぱいに広げる
          height: 55, // 高さを調整
          child: FloatingActionButton.extended(
            backgroundColor: Color.fromARGB(255, 60, 177, 180),
            foregroundColor: const Color.fromARGB(255, 255, 255, 255),
            onPressed: () {
              final currentCard = viewModel.currentCard;

              // デバッグメッセージを追加
              print('currentCard: $currentCard');
              print('selectedImage: $_selectedImage');
              print('imageUrl: ${currentCard?.word?.imageUrl}');

              if (currentCard == null) {
                print('currentCardがnullです');
                return;
              }

              String imageUrl;

              // 画像が削除された場合
              if (_isImageDeleted) {
                imageUrl = ''; // 画像パスを空に設定して削除
              } else if (_selectedImage != null) {
                // 新しい画像が選択されている場合、その画像のパスを使用
                imageUrl = _selectedImage!.path;
              } else {
                // それ以外の場合は、既存のimageUrlを使用
                imageUrl = currentCard.word?.imageUrl ?? '';
              }

              print('最終的なimageUrl: $imageUrl');

              // 編集結果を反映
              viewModel.updateWord(
                wordController.text,
                pronunciationController.text,
                mainMeaningController.text,
                subMeaningController.text,
                sentenceController.text,
                sentenceJpController.text,
                englishDefinitionController.text,
                etymologyController.text,
                memoController.text,
                imageUrl, // 画像のパス
              );

              // 保存して戻る
              Navigator.of(context).pop();
            },
            label: Text(
              '保存する',
              style: TextStyle(
                fontFamily: 'ZenMaruGothic',
                fontWeight: FontWeight.w700, // Bold
                fontSize: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
