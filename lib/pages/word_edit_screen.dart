import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/services.dart';
import 'package:kokotan/view_models/data_view_model.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

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

  File? _selectedImage;
  bool _isImageDeleted = false;
  bool _isDragging = false; // ドラッグ中かどうかを示すフラグ
  bool _isProcessing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ProviderをdidChangeDependencies内で取得
    final viewModel = Provider.of<DataViewModel>(context, listen: false);

    // TextEditingControllerの初期化
    wordController =
        TextEditingController(text: viewModel.currentWord?.word ?? '');
    pronunciationController =
        TextEditingController(text: viewModel.currentWord?.pronunciation ?? '');
    mainMeaningController =
        TextEditingController(text: viewModel.currentWord?.mainMeaning ?? '');
    subMeaningController =
        TextEditingController(text: viewModel.currentWord?.subMeaning ?? '');
    sentenceController =
        TextEditingController(text: viewModel.currentWord?.sentence ?? '');
    sentenceJpController =
        TextEditingController(text: viewModel.currentWord?.sentenceJp ?? '');
    englishDefinitionController = TextEditingController(
        text: viewModel.currentWord?.englishDefinition ?? '');
    etymologyController =
        TextEditingController(text: viewModel.currentWord?.etymology ?? '');
    memoController =
        TextEditingController(text: viewModel.currentWord?.memo ?? '');

    // viewModelからカードを取得し、その後imageUrlを設定
    viewModel.fetchCardById(viewModel.currentCard!.id).then((_) {
      // データが取得されたらimageUrlからFileを生成して_selectedImageに設定
      if (viewModel.currentCard?.word.imageUrl != null &&
          viewModel.currentCard!.word.imageUrl!.isNotEmpty) {
        setState(() {
          _selectedImage = File(viewModel.currentCard!.word.imageUrl!);
        });
      }
    });
  }

  @override
  void dispose() {
    wordController.dispose();
    pronunciationController.dispose();
    mainMeaningController.dispose();
    subMeaningController.dispose();
    sentenceController.dispose();
    sentenceJpController.dispose();
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
      final compressedImage = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        '${imageFile.parent.path}/compressed_${imageFile.uri.pathSegments.last}',
        quality: 70,
        minWidth: 1080,
        minHeight: 1080,
      );

      setState(() {
        _selectedImage = compressedImage;
        _isImageDeleted = false; // 新しい画像を追加したので削除フラグをリセット
      });
    }
  }

  // 画像を削除する
  void _removeImage() {
    setState(() {
      _isImageDeleted = true;
      _selectedImage = null;
    });
  }

  Future<File> _setImage(File imageFile) async {
    // 画像を読み込み
    final originalImage = img.decodeImage(await imageFile.readAsBytes());

    // 圧縮処理 (JPEG品質を85%に設定)
    final compressedImage = img.encodeJpg(originalImage!, quality: 85);

    // 一時ディレクトリに保存
    final tempDir = await getTemporaryDirectory();
    final compressedFile = File('${tempDir.path}/compressed_image.jpeg');
    await compressedFile.writeAsBytes(compressedImage);

    return compressedFile;
  }

  Future<File> saveDroppedImageToDocuments(
      Uint8List data, String fileName) async {
    // ドキュメントディレクトリの取得
    final directory = await getApplicationDocumentsDirectory();

    // 指定されたファイル名で保存
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    // ファイルにデータを書き込み
    await file.writeAsBytes(data);

    return file;
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
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: ListView(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  wordController.text,
                  style: TextStyle(
                    fontFamily: 'ZenMaruGothic',
                    fontWeight: FontWeight.w700,
                    fontSize: 40,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 10),
                Wrap(
                  children: [
                    Text(
                      mainMeaningController.text,
                      style: const TextStyle(
                        fontFamily: 'ZenMaruGothic',
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: Colors.red,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                    if (subMeaningController.text.isNotEmpty) ...[
                      SizedBox(width: 5),
                      Text(
                        subMeaningController.text,
                        style: const TextStyle(
                          fontFamily: 'ZenMaruGothic',
                          fontWeight: FontWeight.w500,
                          fontSize: 22,
                          color: Color(0xFF333333),
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 15),
                // ドロップ対応の画像エリア
                DropRegion(
                  onDropOver: (event) => DropOperation.move,
                  formats: Formats.standardFormats,
                  onPerformDrop: (event) async {
                    setState(() {
                      _isProcessing = true;
                    });

                    final item = event.session.items.first;
                    final reader = item.dataReader!;

                    if (reader.canProvide(Formats.jpeg) ||
                        reader.canProvide(Formats.png)) {
                      final format = reader.canProvide(Formats.jpeg)
                          ? Formats.jpeg
                          : Formats.png;

                      try {
                        // `getFile`メソッドで画像データを取得
                        await reader.getFile(format, (file) async {
                          final Uint8List data = await file.readAll(); // データを取得

                          // ドキュメントディレクトリの取得
                          final appDir =
                              await getApplicationDocumentsDirectory();
                          final imagesDir = Directory('${appDir.path}/images');

                          // ディレクトリが存在しない場合は作成
                          if (!await imagesDir.exists()) {
                            await imagesDir.create(recursive: true);
                          }

                          final permanentFilePath =
                              '${imagesDir.path}/dropped_image_${DateTime.now().millisecondsSinceEpoch}.${format == Formats.jpeg ? 'jpeg' : 'png'}';
                          final permanentFile = File(permanentFilePath);
                          await permanentFile.writeAsBytes(data);

                          // 圧縮処理とパスの設定
                          final compressedFile =
                              await FlutterImageCompress.compressAndGetFile(
                            permanentFile.absolute.path,
                            '${imagesDir.path}/compressed_dropped_image_${DateTime.now().millisecondsSinceEpoch}.jpeg',
                            quality: 70,
                            minWidth: 1080,
                            minHeight: 1080,
                          );

                          setState(() {
                            _selectedImage = compressedFile;
                            _isImageDeleted = false; // 必要であれば追加
                            _isProcessing = false;
                          });
                        }, onError: (error) {
                          print('Error reading image: $error');
                          setState(() {
                            _isProcessing = false;
                          });
                        });
                      } catch (error) {
                        print('Error handling file: $error');
                        setState(() {
                          _isProcessing = false;
                        });
                      }
                    } else {
                      print('Unsupported file format');
                      setState(() {
                        _isProcessing = false;
                      });
                    }
                  },
                  child: GestureDetector(
                    onTap: () => _pickImageFromGallery(),
                    child: Container(
                      height: _selectedImage == null ? 250 : null,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: _selectedImage != null
                            ? null
                            : Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _selectedImage != null
                          ? Stack(
                              children: [
                                Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  key: ValueKey(
                                      _selectedImage!.path), // これで画像のキャッシュを無効化
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _selectedImage = null;
                                        _isImageDeleted = true;
                                      });
                                    },
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
                ),
                SizedBox(height: 16),
                _buildTextFieldWithPaste('英英', englishDefinitionController),
                _buildTextFieldWithPaste('語源', etymologyController),
                _buildTextFieldWithPaste('その他なんでもメモ', memoController),
                SizedBox(height: 70),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _isProcessing
            ? Colors.grey // 処理中の場合はグレー
            : Color.fromARGB(255, 60, 177, 180),
        onPressed: _isProcessing
            ? null
            : () async {
                if (viewModel.currentCard == null) return;

                String imageUrlToSave =
                    _isImageDeleted ? '' : _selectedImage?.path ?? '';

                // データベースの更新処理が完了するまで待機
                await viewModel.updateWordInCurrentCard(
                  wordController.text,
                  pronunciationController.text,
                  mainMeaningController.text,
                  subMeaningController.text,
                  sentenceController.text,
                  sentenceJpController.text,
                  englishDefinitionController.text,
                  etymologyController.text,
                  memoController.text,
                  imageUrlToSave,
                );

                // 更新が完了した後に画面を閉じる
                Navigator.of(context).pop();
              },
        label: _isProcessing
            ? Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    '保存中...',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'ZenMaruGothic',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ],
              )
            : Text(
                '保存する',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'ZenMaruGothic',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
      ),
    );
  }

  Widget _buildTextFieldWithPaste(
      String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            icon: Icon(Icons.paste),
            onPressed: () async {
              ClipboardData? data =
                  await Clipboard.getData(Clipboard.kTextPlain);
              if (data != null) controller.text = data.text!;
            },
          ),
        ),
      ),
    );
  }
}
