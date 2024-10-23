import 'package:flutter/material.dart';
import 'package:kokotan/Algorithm/srs.dart' as srs;
import 'package:kokotan/db/database_helper.dart';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:kokotan/pages/otsukare.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DataViewModel extends ChangeNotifier {
  List<srs.Word> _words = [];
  List<srs.Card> _cards = [];
  bool _isLoading = false;
  List<srs.Word> _searchResults = [];
  srs.Scheduler? scheduler;
  srs.Card? currentCard;
  double _downloadProgress = 0.0; // 追加: ダウンロード進捗を保持
  bool _allDataDownloaded = false;
  bool _20DataDownloaded = false; //最初の20枚のデータがダウンロードされたか？

  DataViewModel() {
    _initialize();
  }

  // 新規カードと復習カードの設定を更新
  Future<void> updateCardSettings({
    int? newCardLimitPermanent, // 永続的な新規カード設定
    int? reviewCardLimitPermanent, // 永続的な復習カード設定
  }) async {
    if (newCardLimitPermanent != null) {
      newCardLimit = newCardLimitPermanent;
      await _prefs?.setInt('newCardLimit', newCardLimit); // 永続化
    }

    if (reviewCardLimitPermanent != null) {
      reviewCardLimit = reviewCardLimitPermanent;
      await _prefs?.setInt('reviewCardLimit', reviewCardLimit); // 永続化
    }

    // デッキ設定を更新
    scheduler?.updateDeckLimits(
      newLimit: getNewCardLimit(),
      reviewLimit: getReviewCardLimit(),
    );

    await scheduler?.reset((srs.Card card) {
      dbHelper.updateCard(card);
    });

    notifyListeners();
  }

  // 新規カードの上限を取得
  int getNewCardLimit() {
    return newCardLimit;
  }

  // 復習カードの上限を取得
  int getReviewCardLimit() {
    return reviewCardLimit;
  }

  int newCardLimit = srs.deckDefaultConf['new']['perDay']; // 初期値をデフォルト設定から取得
  int reviewCardLimit = srs.deckDefaultConf['rev']['perDay']; // 初期値をデフォルト設定から取得

  SharedPreferences? _prefs;
  // SharedPreferencesから設定をロードする
  Future<void> _loadLimitSettings() async {
    _prefs = await SharedPreferences.getInstance();
    newCardLimit =
        _prefs?.getInt('newCardLimit') ?? srs.deckDefaultConf['new']['perDay'];
    reviewCardLimit = _prefs?.getInt('reviewCardLimit') ??
        srs.deckDefaultConf['rev']['perDay'];
    notifyListeners();
  }

  Future<void> _initialize() async {
    await _loadDataDownloadedFlag(); // ここでデータダウンロードフラグを非同期に読み込む
  }

  Future<void> _loadDataDownloadedFlag() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _allDataDownloaded = prefs.getBool('allDataDownloaded') ?? false;
  }

  Future<void> _saveDataDownloadedFlag(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('allDataDownloaded', value);
  }

  Future<void> _save20DataDownloadedFlag(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('20DataDownloaded', value);
  }

  Future<void> _load20DataDownloadedFlag() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _20DataDownloaded = prefs.getBool('20DataDownloaded') ?? false;
  }

  Future<void> initializeData() async {
    print('initializeDataを実行しています');
    await _load20DataDownloadedFlag(); // ここで20枚データダウンロードフラグも読み込む
    print('_20DataDownloaded:$_20DataDownloaded');

    if (_20DataDownloaded) {
      // 20枚のデータがダウンロード済みの場合のみ、スケジューラを初期化
    await fetchWordsAndInitializeScheduler();
    // バックグラウンドで残りのデータをダウンロード
    downloadRemainingDataInBackground();
  }

    print('initializeDataが完了しました');
  }

  List<srs.Word> get words => _words;
  List<srs.Card> get cards => _cards;
  bool get isLoading => _isLoading;

  List<srs.Word> get searchResults => _searchResults;
  srs.Card? get card => currentCard;
  srs.Word? get currentWord => currentCard?.word;
  double get downloadProgress => _downloadProgress; // プログレスを取得

  int get newCardCount => scheduler?.newQueueCount ?? 20;
  // learningCardCountだけは学習queueタイプの総数で数える
  int get learningCardCount => _cards.where((card) => card.queue == 1).length;
  // int get learningCardCount => scheduler?.learningQueueCount ?? 0;
  int get reviewCardCount => scheduler?.reviewQueueCount ?? 0;
  // int get reviewCardCount => _cards.where((card) => card.queue == 2).length;

  //エクセルからデータをダウンロード
  Future<void> downloadAndImportExcel() async {
    print('downloadAndImportExcelを実行しています');
    _isLoading = true;

    notifyListeners();

    try {
      const url =
          'https://kokomirai.jp/wp-content/uploads/2024/08/sa_ver01.xlsx';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/sa_ver01.xlsx');
        await file.writeAsBytes(bytes);

        //20枚のデータをダウンロード
        await _importExcelToDatabase(file);
        print('20枚分のデータがダウンロードされました');

        //20枚のデータがダウンロードされたことを保存
        _20DataDownloaded = true;
        await _save20DataDownloadedFlag(_20DataDownloaded);
        print('_20DataDownloaded:$_20DataDownloaded');
        print("エクセルから20枚分のデータをダウンロードしました");

        await fetchWordsAndInitializeScheduler();
      } else {
        print('Error downloading file: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during download and import: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    print('downloadAndImportExcelが完了しました');
  }

  Future<void> _importExcelToDatabase(File file, {int limit = 20}) async {
    print('_importExcelToDatabaseを実行しています');
    final dbHelper = DatabaseHelper.instance;
    final directory = await getApplicationDocumentsDirectory();
    int wordCount = 0;

    try {
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        for (var row in sheet!.rows) {
          if (row[0]?.value.toString() == 'wordid') {
            continue; // Skip the header row
          }

          int wordId = int.tryParse(row[0]?.value.toString() ?? '') ?? 0;

          // 既にデータベースに存在する単語をスキップ
          if (await dbHelper.doesWordExist(wordId)) {
            continue;
          }

          if (wordCount >= limit) break;

          // 音声ファイルのダウンロードと保存
          String wordVoiceUrl =
              row.length > 2 ? (row[2]?.value?.toString() ?? '') : '';
          String sentenceVoiceUrl =
              row.length > 7 ? (row[7]?.value?.toString() ?? '') : '';
          String wordVoicePath = '';
          String sentenceVoicePath = '';

          if (wordVoiceUrl.isNotEmpty) {
            wordVoicePath = await _downloadAndSaveFile(
                wordVoiceUrl, '${row[0]?.value}_word.mp3', directory.path);
          }

          if (sentenceVoiceUrl.isNotEmpty) {
            sentenceVoicePath = await _downloadAndSaveFile(sentenceVoiceUrl,
                '${row[0]?.value}_sentence.mp3', directory.path);
          }

          srs.Word word = srs.Word(
            id: row.length > 0
                ? (int.tryParse(row[0]?.value.toString() ?? '') ?? 0)
                : 0,
            word: row.length > 1 ? (row[1]?.value?.toString() ?? '') : '',
            pronunciation:
                row.length > 3 ? (row[3]?.value?.toString() ?? '') : '',
            mainMeaning:
                row.length > 4 ? (row[4]?.value?.toString() ?? '') : '',
            subMeaning: row.length > 5 ? (row[5]?.value?.toString() ?? '') : '',
            sentence: row.length > 6 ? (row[6]?.value?.toString() ?? '') : '',
            sentenceJp: row.length > 8 ? (row[8]?.value?.toString() ?? '') : '',
            wordVoice: wordVoicePath, // ローカルの音声ファイルパスを保存
            sentenceVoice: sentenceVoicePath, // ローカルの音声ファイルパスを保存
          );

          if (word.id == 0 ||
              word.word.isEmpty ||
              word.mainMeaning.isEmpty ||
              word.sentence.isEmpty ||
              word.sentenceJp.isEmpty) {
            continue;
          }

          await dbHelper.insertWord(word);

          srs.Card card = srs.Card(word); // カスタムのCardクラスを使用
          await dbHelper.insertCard(card);

          wordCount++;
          // 進捗率を更新
          _downloadProgress = wordCount / limit;
          notifyListeners();

          if (wordCount >= limit) break;
        }
        if (wordCount >= limit) break;
      }
      print('_importExcelToDatabaseが完了しました');
    } catch (e) {
      print('Error importing Excel data: $e');
    }
  }

  Future<String> _downloadAndSaveFile(
      String url, String fileName, String dir) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final file = File('$dir/$fileName');
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } else {
      throw Exception('Failed to download file');
    }
  }

  Future<void> downloadRemainingDataInBackground() async {
    if (_allDataDownloaded) {
      print('全てのデータがダウンロードされています');
      return;
    }
    print('残りのデータをバックグラウンドでダウンロードします');

    // すべてのデータをインポートするように設定 (limit=無制限)
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/sa_ver01.xlsx');
    if (await file.exists()) {
      // 既に存在するExcelファイルからデータを取り込む
      await _importExcelToDatabase(file, limit: 1484);
      print('全てのデータがダウンロードされました');

      // フラグをtrueに設定
      await _saveDataDownloadedFlag(true);
      _allDataDownloaded = true;
    } else {
      print('Error: Excel file not found for background import.');
    }
  }

  Future<void> fetchWordsAndInitializeScheduler() async {
    print('fetchWordsAndInitializeSchedulerを実行しています');

    final dbHelper = DatabaseHelper.instance;
    final wordRows = await dbHelper.queryAllWords();
    final cardRows = await dbHelper.queryAllCards();

    List<srs.Word> words =
        wordRows.map((row) => srs.Word.fromMap(row)).toList();
    List<srs.Card> cards = cardRows.map((row) {
      int wordId = row['word_id'];
      srs.Word word = words.firstWhere((w) => w.id == wordId);
      return srs.Card.fromMap(row, word);
    }).toList();

    _words = words;
    _cards = cards;
    _searchResults = words;

    // コレクションとデッキを初期化
    var collection = srs.Collection();
    var deckName = 'Default Deck';
    collection.addDeck(deckName);

    for (var card in cards) {
      collection.addCardToDeck(deckName, card);
    }

    scheduler = srs.Scheduler(collection);
    await scheduler!.initializeScheduler(onDueUpdated: (card) {
      dbHelper.updateCard(card); // データベースを更新
    });
    scheduler!.fillAll();
    currentCard = await scheduler!.getCard();
    notifyListeners();
    print('fetchWordsAndInitializeSchedulerが完了しました');
  }

  Future<Map<String, int>> fetchCardQueueDistribution() async {
    final dbHelper = DatabaseHelper.instance;
    final cardRows = await dbHelper.queryAllCards();

    int newCount = 0;
    int learnCount = 0;
    int reviewCount = 0;

    for (var row in cardRows) {
      int queue = row['queue'];
      if (queue == 0) {
        newCount++;
      } else if (queue == 1) {
        learnCount++;
      } else if (queue == 2) {
        reviewCount++;
      }
    }

    return {
      'New': newCount,
      'Learn': learnCount,
      'Review': reviewCount,
    };
  }

  Future<void> answerCard(int ease, BuildContext context) async {
    if (scheduler != null && currentCard != null) {
      scheduler!.answerCard(currentCard!, ease);

      // カード情報を更新
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.updateCard(currentCard!);
      if (newCardCount == 0 && learningCardCount == 0 && reviewCardCount == 0) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => OtsukareScreen()));
      }
      currentCard = await getCard();
      notifyListeners();
    }
  }

  Future<srs.Card?> getCard() async {
    return await scheduler?.getCard(); // await で非同期の結果を待つ
  }

  void search(String query) {
    final results = _words.where((word) {
      final wordStr = word.word.toLowerCase();
      final input = query.toLowerCase();
      return wordStr.contains(input);
    }).toList();

    _searchResults = results;
    notifyListeners();
  }

  // currentCardを設定するメソッド
  void setCurrentCard(srs.Card card) {
    currentCard = card;
    notifyListeners(); // 状態が変更されたことを通知
  }

  // 編集されたWordデータをcurrentCardに反映
  void updateWord(
      String word,
      String pronunciation,
      String mainMeaning,
      String subMeaning,
      String sentence,
      String sentenceJp,
      String englishDefinition,
      String etymology,
      String memo,
      String? imageUrl) {
    print('updateWordを発動しました');
    if (currentCard != null) {
      currentCard!.word = srs.Word(
        id: currentCard!.word.id,
        word: word,
        pronunciation: pronunciation.isNotEmpty ? pronunciation : null,
        mainMeaning: mainMeaning,
        subMeaning: subMeaning.isNotEmpty ? subMeaning : null,
        sentence: sentence,
        sentenceJp: sentenceJp,
        wordVoice: currentCard!.word.wordVoice,
        sentenceVoice: currentCard!.word.sentenceVoice,
        englishDefinition: englishDefinition,
        etymology: etymology,
        memo: memo,
        imageUrl: imageUrl,
      );
      updateCurrentCard();
    } else {
      print('currentCardがnullだったのでupdateCurrentCardを発動しませんでした');
    }
  }

  // currentCardをデータベースに保存
  Future<void> updateCurrentCard() async {
    print('updateCurrentCardを発動しました');
    if (currentCard != null) {
      await dbHelper.updateCard(currentCard!);
      notifyListeners();
    }
  }

//   void addCardToHistory(srs.Card card) {
//     // 履歴に同じIDのカードが既に存在するか確認
//     bool alreadyExists =
//         _cardHistory.any((historyCard) => historyCard.id == card.id);

//     if (alreadyExists) {
//       print('同じカードが履歴に存在するため、追加しません');
//       return; // 同じカードが存在する場合は何もしない
//     }

//     // カードのディープコピーを手動で作成
//     final copiedCard = srs.Card(
//       card.word, // Wordクラスはそのままコピー（変更しないならそのまま）
//       id: card.id, // IDもそのままコピー
//     )
//       ..due = card.due
//       ..crt = card.crt
//       ..type = card.type
//       ..queue = card.queue
//       ..ivl = card.ivl
//       ..factor = card.factor
//       ..reps = card.reps
//       ..lapses = card.lapses
//       ..left = card.left;

//     // コピーしたカードを履歴に追加
//     _cardHistory.add(copiedCard);

//     // 履歴の長さが10枚を超えたら、古い履歴を削除
//     if (_cardHistory.length > 10) {
//       _cardHistory.removeAt(0); // 一番古い履歴を削除
//     }

//     // リスナーに変更を通知
//     notifyListeners();
//   }

//   Future<srs.Card?> getPreviousCard() async {
//   if (_cardHistory.isNotEmpty) {
//     // 履歴から前のカードを取得
//     final previousCard = _cardHistory.removeLast();

//     // データベース上の元のカードを取得（カードのIDで検索）
//     final originalCard = await dbHelper.queryCardById(previousCard.id);

//     if (originalCard != null) {
//       // データベースの元のカードの情報を、履歴のカードの状態で更新
//       originalCard.due = previousCard.due;
//       originalCard.crt = previousCard.crt;
//       originalCard.type = previousCard.type;
//       originalCard.queue = previousCard.queue;
//       originalCard.ivl = previousCard.ivl;
//       originalCard.factor = previousCard.factor;
//       originalCard.reps = previousCard.reps;
//       originalCard.lapses = previousCard.lapses;
//       originalCard.left = previousCard.left;

//       // 更新したカードをデータベースに保存
//       await dbHelper.updateCard(originalCard);
//     }

//     // 現在のカードとして previousCard を反映
//     currentCard = previousCard;

//     // キューの中身をクリア
//     scheduler!.newQueue = [];
//     scheduler!.lrnQueue = [];
//     scheduler!.revQueue = [];

//     // キューを補充
//     scheduler!.fillAll();

//     notifyListeners(); // UI更新を通知
//     return previousCard;
//   }
//   return null; // 履歴がない場合はnullを返す
// }
}

// ヘルプURLを開くためのメソッド
Future<void> launchHelpURL() async {
  const url =
      'https://clumsy-surfboard-249.notion.site/06461862055f482d97fdb8c64eaeb56e?pvs=4';
  final Uri uri = Uri.parse(url); // Uriを生成
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw 'Could not launch $url';
  }
}
