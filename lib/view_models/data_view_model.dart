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

  DateTime _currentTime = DateTime.now(); // プライベートな currentTime 変数
  DateTime get currentTime => _currentTime; // getter

  void setCurrentTime(DateTime newTime) async {
    _currentTime = newTime;
    notifyListeners(); // データの変更を通知
    await saveCurrentTime(newTime); // 変更後、現在の時間を保存
  }

  // Scheduler の checkDay を発動
  Future<void> triggerCheckDay() async {
    print('trigerCheckDayが発動しました');

    if (scheduler != null) {
      // currentTime を渡して checkDay を発動
      await scheduler!.checkDay(customCurrentTime: currentTime);
      currentCard = await scheduler!.getCard(); // checkDay後に新しいカードを取得
      notifyListeners();
    }
  }

  Future<void> saveCurrentTime(DateTime currentTime) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentTime', currentTime.toIso8601String());
  }

  Future<void> loadCurrentTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedTime = prefs.getString('currentTime');
    if (savedTime != null) {
      _currentTime = DateTime.parse(savedTime);
    } else {
      _currentTime = DateTime.now();
    }
    notifyListeners();
  }

  DataViewModel() {
    _loadDataDownloadedFlag();
  }

  Future<void> _loadDataDownloadedFlag() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _allDataDownloaded = prefs.getBool('allDataDownloaded') ?? false;
  }

  Future<void> _saveDataDownloadedFlag(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('allDataDownloaded', value);
  }

  Future<void> initializeData() async {
    await fetchWordsAndInitializeScheduler();
    // バックグラウンドで残りのデータをダウンロード
    downloadRemainingDataInBackground();
  }

  List<srs.Word> get words => _words;
  List<srs.Card> get cards => _cards;
  bool get isLoading => _isLoading;
  List<srs.Word> get searchResults => _searchResults;
  srs.Card? get card => currentCard;
  srs.Word? get currentWord => currentCard?.word;
  double get downloadProgress => _downloadProgress; // プログレスを取得

  int get newCardCount => scheduler?.newQueue.length ?? 0;
  // learningCardCountだけは学習queueタイプの総数で数える
  int get learningCardCount => _cards.where((card) => card.queue == 1).length;
  // int get learningCardCount => scheduler?.learningQueueCount ?? 0;
  int get reviewCardCount => scheduler?.revQueue.length ?? 0;
  // int get reviewCardCount => _cards.where((card) => card.queue == 2).length;

  Future<void> downloadAndImportExcel() async {
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

        await _importExcelToDatabase(file);
        await fetchWordsAndInitializeScheduler();
        print("Excel downloaded and imported successfully！");
      } else {
        print('Error downloading file: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during download and import: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _importExcelToDatabase(File file, {int limit = 20}) async {
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
          print(wordId);

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
            print('Downloaded word voice: $wordVoicePath');
          }

          if (sentenceVoiceUrl.isNotEmpty) {
            sentenceVoicePath = await _downloadAndSaveFile(sentenceVoiceUrl,
                '${row[0]?.value}_sentence.mp3', directory.path);
            print('Downloaded sentence voice: $sentenceVoicePath');
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

          if (wordCount >= limit) {
            break;
          }

          print('Inserted word: ${word.word}, card ID: ${card.id}');
        }
        if (wordCount >= limit) break;
      }
      print('Excel data imported successfully');

      // インポート完了後に fillNew() を実行
      if (scheduler != null) {
        scheduler?.checkDay();
        print("fillNew() executed after data import.");
      }
    } catch (e) {
      print('Error importing Excel data: $e');
    }
  }

  Future<String> _downloadAndSaveFile(
      String url, String fileName, String dir) async {
    print('Downloading file: $url');
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
      print(
          'All data has already been downloaded. Skipping background download.');
      return;
    }
    print('Starting background download of remaining data...');

    // すべてのデータをインポートするように設定 (limit=無制限)
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/sa_ver01.xlsx');
    if (await file.exists()) {
      // 既に存在するExcelファイルからデータを取り込む
      await _importExcelToDatabase(file, limit: 1484);
      print('Background download completed successfully');

      // フラグをtrueに設定
      await _saveDataDownloadedFlag(true);
      _allDataDownloaded = true;
    } else {
      print('Error: Excel file not found for background import.');
    }
  }

  Future<void> fetchWordsAndInitializeScheduler() async {
    print('Fetching words, cards, and initializing scheduler...');

    final dbHelper = DatabaseHelper.instance;

    // すべての単語とカードをデータベースから取得
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

    // Schedulerの初期化
    scheduler = srs.Scheduler(collection);
    await scheduler!.initializeScheduler(); // 非同期で初期化を待つ

    //データベースからnewQueueとrevQueueを取得
    final newQueueData = await dbHelper.queryCardsInQueue(0); // 0 = newQueue
    final newQueueCards = newQueueData
        .map((map) {
          int cardId = map['card_id']; // card_id を取得
          return _cards.firstWhere((card) => card.id == cardId,
              orElse: () => srs.Card(srs.Word(
                    id: -1,
                    word: '',
                    pronunciation: '',
                    mainMeaning: '',
                    subMeaning: '',
                    sentence: '',
                    sentenceJp: '',
                    wordVoice: '',
                    sentenceVoice: '',
                  )) // ダミーのCardオブジェクトを返す
              );
        })
        .where((card) => card.id != -1)
        .toList(); // ダミーオブジェクトを除外

    final revQueueData = await dbHelper.queryCardsInQueue(2); // 2 = revQueue

    final revQueueCards = revQueueData
        .map((map) {
          int cardId = map['card_id']; // card_id を取得
          return _cards.firstWhere((card) => card.id == cardId,
              orElse: () => srs.Card(srs.Word(
                    id: -1,
                    word: '',
                    pronunciation: '',
                    mainMeaning: '',
                    subMeaning: '',
                    sentence: '',
                    sentenceJp: '',
                    wordVoice: '',
                    sentenceVoice: '',
                  )) // ダミーのCardオブジェクトを返す
              );
        })
        .where((card) => card.id != -1)
        .toList(); // ダミーオブジェクトを除外

    // Scheduler に設定
    scheduler?.newQueue = newQueueCards;
    scheduler?.revQueue = revQueueCards;

    currentCard = await scheduler!.getCard();
    notifyListeners();
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

      // キューから今のカードを削除する
      await dbHelper.removeCardFromQueue(currentCard!.id, currentCard!.queue);

      // 全てのキューが空であれば「お疲れ様」画面に遷移
      if (newCardCount == 0 && learningCardCount == 0 && reviewCardCount == 0) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => OtsukareScreen()));
      }

      // 次のカードを取得
      currentCard = await scheduler!.getCard(); // await を使用
      notifyListeners();
    }
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
}
