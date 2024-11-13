import 'package:flutter/material.dart';
import 'package:kokotan/Algorithm/srs.dart' as srs;
import 'package:kokotan/db/database_helper.dart';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:kokotan/model/deck_list.dart';
import 'package:kokotan/pages/otsukare.dart';
import 'package:kokotan/model/deck_list.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert'; // JSONを扱うために必要

class DataViewModel extends ChangeNotifier {
  final dbHelper = DatabaseHelper.instance; // クラス全体で1度だけインスタンス化

  List<srs.Word> _words = [];
  List<srs.Card> _cards = [];
  List<srs.Word> _searchResults = [];
  srs.Scheduler? scheduler;
  srs.Card? currentCard;
  double _downloadProgress = 0.0; // 追加: ダウンロード進捗を保持
  bool _isAllDataDownloaded = false;
  bool _is20DataDownloaded = false; //最初の20枚のデータがダウンロードされたか？
  Map<String, Map<String, dynamic>> deckData = InitialDeckData;
  Map<int, double> downloadProgressMap = {};

  Map<int, int> todayNewCardsCount = {}; // デッキIDごとに新規カードの処理数を格納
  Map<int, int> todayReviewCardsCount = {}; // デッキIDごとにレビューカードの処理数を格納

  DataViewModel() {
    _initialize();
  }

  // ダウンロード状態を更新
  void updateDownloadStatus(String deckID, DownloadStatus status) {
    if (deckData.containsKey(deckID)) {
      deckData[deckID]!['isDownloaded'] = status;
      notifyListeners(); // UIに通知
    }
  }

  DownloadStatus getDownloadStatus(String deckID) {
    return deckData[deckID]?['isDownloaded'] ?? DownloadStatus.notDownloaded;
  }

  String? getDownloadingDeckID() {
    // 初期データのリストを走査して、ダウンロード中のデッキIDを探す
    for (String deckID in deckData.keys) {
      if (getDownloadStatus(deckID) == DownloadStatus.downloading) {
        return deckID; // ダウンロード中のデッキIDを返す
      }
    }
    return null; // ダウンロード中のデッキが見つからない場合はnullを返す
  }

  Future<void> initializeDeckData() async {
    // ロードしたデータが空またはnullの場合、InitialDeckDataをコピーして設定
    Map<String, Map<String, dynamic>>? loadedData = await loadDeckData();

    if (loadedData.isEmpty) {
      // データがない場合、InitialDeckDataをdeckDataにコピー
      deckData = Map<String, Map<String, dynamic>>.from(InitialDeckData);
      await saveDeckData(deckData); // 初期データを保存
      print("initializeDeckData: デフォルトのInitialDeckDataを保存しました");
    } else {
      // データがある場合、ロードしたデータを使用
      deckData = loadedData;
    }

    print("initializeDeckData: 最終的なdeckData = $deckData"); // デバッグログで確認
  }

  Future<void> saveDeckData(Map<String, Map<String, dynamic>> data) async {
    // まず、DownloadStatus を文字列に変換したデータを作成
    Map<String, Map<String, dynamic>> dataToSave = data.map((key, value) {
      var newValue = Map<String, dynamic>.from(value);
      // DownloadStatus を文字列に変換
      newValue['isDownloaded'] =
          (value['isDownloaded'] as DownloadStatus).toString().split('.').last;
      return MapEntry(key, newValue);
    });

    // 変換したデータを JSON 形式で SharedPreferences に保存
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonData = jsonEncode(dataToSave);
    await prefs.setString('deckData', jsonData);
  }

  Future<Map<String, Map<String, dynamic>>> loadDeckData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonData = prefs.getString('deckData');
    if (jsonData != null) {
      // JSON 形式から Map にデコード
      Map<String, dynamic> decodedData = jsonDecode(jsonData);
      return decodedData.map((key, value) {
        var newValue = Map<String, dynamic>.from(value);
        // isDownloaded を DownloadStatus に変換
        newValue['isDownloaded'] = DownloadStatus.values.firstWhere(
            (e) => e.toString().split('.').last == value['isDownloaded']);
        return MapEntry(key, newValue);
      });
    }
    return {}; // データがない場合は空のマップを返す
  }

  // 新規カードと復習カードの設定を更新
  Future<void> updateCardSettings({
    int? newCardLimit, // 永続的な新規カード設定
    int? reviewCardLimit, // 永続的な復習カード設定
    required int deckID, // required修飾子を追加
  }) async {
    if (newCardLimit != null) {
      deckData[deckID.toString()]?["newPerDayLimit"] = newCardLimit;
    }
    if (reviewCardLimit != null) {
      deckData[deckID.toString()]?["reviewPerDayLimit"] = reviewCardLimit;
    }

    saveDeckData(deckData);

    //なんかassignのやつ
    await scheduler!.assignDueToNewCardByDeckID(
        deckID, dbHelper.updateCard, deckData); // updateCardをコールバックとして渡す
    scheduler!.fillNew(alwaysRun: true);
    scheduler!.fillRev(alwaysRun: true, deckData: deckData);

    notifyListeners();
  }

  SharedPreferences? _prefs;

// // ダウンロード状況を保存する関数
//   Future<void> saveDeckData(Map<String, Map<String, dynamic>> deckData) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();

//     // MapをJSON形式のStringに変換
//     Map<String, dynamic> jsonReadyData = deckData.map((key, value) {
//       return MapEntry(key, {
//         ...value,
//         'isDownloaded': value['isDownloaded'].toString(), // EnumをStringに変換
//       });
//     });
//     String jsonString = json.encode(jsonReadyData);

//     await prefs.setString('deckData', jsonString);
//   }

  // Future<Map<String, Map<String, dynamic>>> loadDeckData() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? jsonString = prefs.getString('deckData');

  //   if (jsonString != null) {
  //     // JSONデータをデコードし、型を明確に指定
  //     Map<String, dynamic> decodedData =
  //         Map<String, dynamic>.from(json.decode(jsonString));

  //     // `isDownloaded`のEnum変換を含めて構造を再構築
  //     Map<String, Map<String, dynamic>> deckData =
  //         decodedData.map((key, value) {
  //       return MapEntry(
  //         key,
  //         {
  //           ...Map<String, dynamic>.from(value),
  //           'isDownloaded': DownloadStatus.values.firstWhere(
  //             (e) => e.toString() == value['isDownloaded'],
  //             orElse: () => DownloadStatus.notDownloaded,
  //           ),
  //         },
  //       );
  //     });

  //     return deckData;
  //   } else {
  //     return {}; // データがない場合は空のMapを返す
  //   }
  // }

  // // SharedPreferencesから設定をロードする
  // Future<void> _loadLimitSettings() async {
  //   _prefs = await SharedPreferences.getInstance();
  //   newCardLimit =
  //       _prefs?.getInt('newCardLimit') ?? srs.deckDefaultConf['new']['perDay'];
  //   reviewCardLimit = _prefs?.getInt('reviewCardLimit') ??
  //       srs.deckDefaultConf['rev']['perDay'];
  //   notifyListeners();
  // }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    // _loadLimitSettings();

    await _loadAllDataDownloadedFlag(); // ここでデータダウンロードフラグを非同期に読み込む
    await initializeDeckData(); // deckDataにロード済みデータまたはデフォルトをセット
  }

  Future<void> _loadAllDataDownloadedFlag() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isAllDataDownloaded = prefs.getBool('allDataDownloaded') ?? false;
  }

  Future<void> _saveAllDataDownloadedFlag(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('allDataDownloaded', value);
  }

  Future<void> _save20DataDownloadedFlag(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('20DataDownloaded', value);
  }

  Future<void> _load20DataDownloadedFlag() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _is20DataDownloaded = prefs.getBool('20DataDownloaded') ?? false;
  }

  Future<void> initializeData() async {
    print('initializeDataを実行しています');
    await fetchWordsAndInitializeScheduler();
    // バックグラウンドで残りのデータをダウンロード
    downloadRemainingData();

    print('initializeDataが完了しました');
  }

  List<srs.Word> get words => _words;
  List<srs.Card> get cards => _cards;
  bool get is20DataDownloaded => _is20DataDownloaded;
  bool get isAllDataDownloaded => _isAllDataDownloaded;

  List<srs.Word> get searchResults => _searchResults;
  srs.Card? get card => currentCard;
  srs.Word? get currentWord => currentCard?.word;
  double get downloadProgress => _downloadProgress; // プログレスを取得

  // newQueueのカード数を取得
  int newCardCountByDeckID(int deckID) {
    return scheduler!.newQueue.where((card) => card.did == deckID).length;
  }

  int newCardCountByDeckIDforRecord(int deckID) {
    return _cards.where((card) => card.did == deckID && card.queue == 0).length;
  }

  // lrnQueueのカード数を取得
  int learningCardCountByDeckID(int deckID) {
    return _cards.where((card) => card.did == deckID && card.queue == 1).length;
  }

  // revQueueのカード数を取得
  int reviewCardCountByDeckID(int deckID) {
    return scheduler!.revQueue.where((card) => card.did == deckID).length;
  }

  int reviewCardCountByDeckIDforRecord(int deckID) {
    return _cards.where((card) => card.did == deckID && card.queue == 2).length;
  }

  int totalCardCountByDeckID(int deckID) {
    int newCardCount = newCardCountByDeckID(deckID);
    int learningCardCount = learningCardCountByDeckID(deckID);
    int reviewCardCount = reviewCardCountByDeckID(deckID);

    return newCardCount + learningCardCount + reviewCardCount;
  }

  //エクセルからデータをダウンロード
  Future<void> downloadInitialData() async {
    print('downloadAndImportExcelを実行しています');

    try {
      // メソッドを呼び出して結果を受け取る
      var result = await downloadDeckFile();

      if (result != null) {
        print('デッキID: ${result['deckID']}');
        print('ファイルパス: ${result['file'].path}');
        int deckID = int.parse(result['deckID']);
        File file = result['file'];

        //20枚のデータをダウンロード
        await _importExcelToDatabase(file, deckID);
        print('20枚分のデータがダウンロードされました');

        await fetchWordsAndInitializeScheduler();
      } else {
        print('Error downloading file');
      }
    } catch (e) {
      print('Error during download and import: $e');
    } finally {
      notifyListeners();
    }
    print('downloadAndImportExcelが完了しました');
  }

  Future<void> _importExcelToDatabase(File file, int deckID,
      {int limit = 20}) async {
    print('_importExcelToDatabaseを実行しています');
    final directory = await getApplicationDocumentsDirectory();
    int wordCount = 0;

    try {
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      final db = await dbHelper.database; // データベースをawaitで取得する

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        for (var row in sheet!.rows) {
          if (row[0]?.value.toString() == 'wordid') continue; // ヘッダー行をスキップ

          int wordId = int.tryParse(row[0]?.value.toString() ?? '') ?? 0;
          String wordVoicePath = '${directory.path}/${row[0]?.value}_word.mp3';
          String sentenceVoicePath =
              '${directory.path}/${row[0]?.value}_sentence.mp3';

          // ファイルとサイズの存在確認
          File wordVoiceFile = File(wordVoicePath);
          File sentenceVoiceFile = File(sentenceVoicePath);
          bool wordFileExists = wordVoiceFile.existsSync();
          bool sentenceFileExists = sentenceVoiceFile.existsSync();
          int wordFileSize = wordFileExists ? wordVoiceFile.lengthSync() : 0;
          int sentenceFileSize =
              sentenceFileExists ? sentenceVoiceFile.lengthSync() : 0;

          // データベースに存在確認
          bool cardExists = await dbHelper.doesCardExistWithWord(wordId);

          await db.transaction((txn) async {
            if (!cardExists) {
              print('WordIDが存在しないため、新規に挿入します。:$wordId');
              String wordVoiceUrl =
                  row.length > 2 ? (row[2]?.value?.toString() ?? '') : '';
              String sentenceVoiceUrl =
                  row.length > 7 ? (row[7]?.value?.toString() ?? '') : '';

              if (wordVoiceUrl.isNotEmpty) {
                wordVoicePath = await _downloadAndSaveFileWithRetry(
                    wordVoiceUrl, '${row[0]?.value}_word.mp3', directory.path);
              }
              if (sentenceVoiceUrl.isNotEmpty) {
                sentenceVoicePath = await _downloadAndSaveFileWithRetry(
                    sentenceVoiceUrl,
                    '${row[0]?.value}_sentence.mp3',
                    directory.path);
              }

              srs.Word word = srs.Word(
                id: wordId,
                word: row.length > 1 ? (row[1]?.value?.toString() ?? '') : '',
                pronunciation:
                    row.length > 3 ? (row[3]?.value?.toString() ?? '') : '',
                mainMeaning:
                    row.length > 4 ? (row[4]?.value?.toString() ?? '') : '',
                subMeaning:
                    row.length > 5 ? (row[5]?.value?.toString() ?? '') : '',
                sentence:
                    row.length > 6 ? (row[6]?.value?.toString() ?? '') : '',
                sentenceJp:
                    row.length > 8 ? (row[8]?.value?.toString() ?? '') : '',
                wordVoice: wordVoicePath,
                sentenceVoice: sentenceVoicePath,
              );

              await txn.insert(DatabaseHelper.wordTable, word.toMap());
              srs.Card card = srs.Card(word, deckID);
              await txn.insert(DatabaseHelper.cardTable, card.toMap());
            } else if (!wordFileExists ||
                wordFileSize == 0 ||
                !sentenceFileExists ||
                sentenceFileSize == 0) {
              print('音声ファイルが壊れているか、存在しません。再ダウンロードします。:$wordId');
              String wordVoiceUrl =
                  row.length > 2 ? (row[2]?.value?.toString() ?? '') : '';
              String sentenceVoiceUrl =
                  row.length > 7 ? (row[7]?.value?.toString() ?? '') : '';

              if (wordVoiceUrl.isNotEmpty) {
                wordVoicePath = await _downloadAndSaveFileWithRetry(
                    wordVoiceUrl, '${row[0]?.value}_word.mp3', directory.path);
              }
              if (sentenceVoiceUrl.isNotEmpty) {
                sentenceVoicePath = await _downloadAndSaveFileWithRetry(
                    sentenceVoiceUrl,
                    '${row[0]?.value}_sentence.mp3',
                    directory.path);
              }

              await txn.update(
                  DatabaseHelper.wordTable,
                  {
                    'word_voice': wordVoicePath,
                    'sentence_voice': sentenceVoicePath,
                  },
                  where: '${DatabaseHelper.columnId} = ?',
                  whereArgs: [wordId]);
            } else {
              print('単語も音声ファイルも既に存在するため、スキップします:$wordId');
              return;
            }
          });

          wordCount++;
          downloadProgressMap[deckID] = wordCount / limit;
          notifyListeners();

          if (wordCount >= limit) {
            print('Limit reached. Breaking outer loops.');
            break;
          }
        }
        if (wordCount >= limit) break;
      }
      print('_importExcelToDatabaseが完了しました');
    } catch (e) {
      print('Error importing Excel data: $e');
    }
  }

  // デッキIDとダウンロードされたファイルを返すメソッド
  Future<Map<String, dynamic>?> downloadDeckFile() async {
// ダウンロード中のデッキIDを取得
    String? downloadingDeckID = getDownloadingDeckID();

    if (downloadingDeckID != null) {
      try {
        // isDownloaded が downloading のデッキを探す
        String? fileUrl = deckData[downloadingDeckID]?['fileUrl'];
        String? deckID = downloadingDeckID;

        if (fileUrl == null || deckID == null) {
          print('ダウンロード中のデッキが見つかりません');
          return null;
        }

        // ファイルをダウンロード
        final response = await http.get(Uri.parse(fileUrl!));
        if (response.statusCode == 200) {
          print('ファイルが正常に取得されました');

          final bytes = response.bodyBytes;
          final directory = await getApplicationDocumentsDirectory();
          print('保存ディレクトリ: ${directory.path}');

          final file = File('${directory.path}/$deckID.xlsx');
          await file.writeAsBytes(bytes);

          print('ダウンロードが完了しました: $fileUrl');

          return {
            'deckID': deckID,
            'file': file,
          };
        } else {
          print('ファイルのダウンロード中にエラーが発生しました: ${response.statusCode}');
          return null;
        }
      } catch (e) {
        print('エラーが発生しました: $e');
        return null;
      }
    }
  }

  Future<void> updateCardsList() async {
    try {
      // カードデータを取得
      final cardRows = await dbHelper.queryAllCards();

      // デバッグメッセージ
      print('Updating _cards with ${cardRows.length} entries');

      // 各行をカードオブジェクトに変換してリストに追加
      _cards = cardRows.map((row) {
        int wordId = row['word_id'];

        // 対応するWordオブジェクトを見つけてからCardを作成
        srs.Word word = _words.firstWhere((w) => w.id == wordId,
            orElse: () => srs.Word.empty());
        return srs.Card.fromMap(row, word);
      }).toList();

      // 更新後にリスナーに通知
      notifyListeners();
    } catch (e) {
      print('Error updating _cards: $e');
    }
  }

// リトライ機能を持つダウンロード関数
  Future<String> _downloadAndSaveFileWithRetry(
      String url, String fileName, String dir,
      {int retries = 3}) async {
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final file = File('$dir/$fileName');
          await file.writeAsBytes(response.bodyBytes);
          print('File downloaded and saved to: $file.path');
          return file.path;
        } else {
          print('Failed to download file: ${response.statusCode}');
        }
      } catch (e) {
        print('Error downloading file: $e');
      }
      print('Retrying download ($attempt/$retries)...');
    }
    throw Exception('Failed to download file after $retries retries.');
  }

  // 再ダウンロードとインポートメソッド
  Future<void> reDownloadAndImportExcel() async {
    print('[reDownloadAndImportExcel] メソッドが発動しました');

    try {
      final directory = await getApplicationDocumentsDirectory();
      print('[reDownloadAndImportExcel] Documentsディレクトリ: ${directory.path}');

      final file = File('${directory.path}/sa_ver01.xlsx');
      print('[reDownloadAndImportExcel] ファイルパス: ${file.path}');

      await downloadRemainingData();
      print('[reDownloadAndImportExcel] データダウンロードが完了しました');
    } catch (e) {
      print('[reDownloadAndImportExcel] エラーが発生しました: $e');
    }

    print('[reDownloadAndImportExcel] メソッドが完了しました');
  }

  Future<String> _downloadAndSaveFile(
      String url, String fileName, String dir) async {
    try {
      // ディレクトリが存在するか確認し、なければ作成
      final directory = Directory(dir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        print('Directory created at: $dir');
      } else {
        print('Directory exists at: $dir');
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File('$dir/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        // ファイルサイズの確認
        final fileSize = await file.length();
        print('File downloaded and saved to: ${file.path}');
        print('File size: $fileSize bytes');

        // ファイルの存在確認
        if (await file.exists()) {
          print('File exists at: ${file.path}');
        } else {
          print('File does not exist at: ${file.path}');
        }

        return file.path;
      } else {
        print('Failed to download file: ${response.statusCode}');
        throw Exception('Failed to download file');
      }
    } catch (e) {
      print('Error downloading file: $e');
      return ''; // 空のパスを返す
    }
  }

  Future<void> downloadRemainingData() async {
    if (deckData['isDownloaded'] == DownloadStatus.downloaded) {
      print('全てのデータがダウンロードされています');
      return;
    }

    print('残りのデータをバックグラウンドでダウンロードします');

    //resultがnullになるまで繰り返す
    while (true) {
      var result = await downloadDeckFile();
      if (result != null) {
        int deckID = int.parse(result['deckID']);
        File file = result['file'];

        // 既に存在するExcelファイルからデータを取り込む
        await _importExcelToDatabase(file, deckID, limit: 10000);
        print('${deckData[deckID.toString()]!['deckName']}の全てのデータがダウンロードされました');

        // ダウンロード完了後、ステータスを更新。保存する必要もあり
        deckData['$deckID']!['isDownloaded'] = DownloadStatus.downloaded;
        saveDeckData(deckData);
      } else {
        print('すべてのデータがダウンロード済みになっています');
        break; // resultがnullの場合、ループを終了
      }
    }
  }

  Future<void> fetchWordsAndInitializeScheduler() async {
    print('fetchWordsAndInitializeSchedulerを実行しています');

    final wordRows = await dbHelper.queryAllWords();
    final cardRows = await dbHelper.queryAllCards();

    List<srs.Word> words =
        wordRows.map((row) => srs.Word.fromMap(row)).toList();
    List<srs.Card> cards = cardRows.map((row) {
      int wordId = row['word_id'];
      int deckId = row['deck_id']; // デッキIDを取得

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
    await scheduler!.initializeScheduler(
      onDueUpdated: (card) {
        dbHelper.updateCard(card); // データベースを更新
      },
      deckData: deckData, // deckDataを渡す
    );

    // scheduler!.updateDeckLimits(
    //   newLimit: getNewCardLimit(),
    //   reviewLimit: getReviewCardLimit(),
    // );
    scheduler!.updateNewCardRatio(); //再起動でnewCardModulusを初期化
    scheduler!.fillAll(deckData);
    notifyListeners();
    print('fetchWordsAndInitializeSchedulerが完了しました');
  }

  Future<void> refreshList() async {
    // データの再読み込み処理
    _words = await fetchUpdatedWords();
    _searchResults = _words;
    notifyListeners(); // リスト更新を通知
  }

  Future<List<srs.Word>> fetchUpdatedWords() async {
    // データベースから最新の単語リストを取得
    final wordRows = await dbHelper.queryAllWords();
    List<srs.Word> words =
        wordRows.map((row) => srs.Word.fromMap(row)).toList();
    return words;
  }

  Future<Map<String, Map<String, int>>> futureCardData =
      Future.value({}); // 空のマップで初期化

  Future<Map<String, Map<String, int>>>
      fetchAllDecksCardQueueDistribution() async {
    final cardRows = await dbHelper.queryAllCards(); // すべてのカードをデータベースから取得
    if (cardRows.isEmpty) return {}; // データがない場合、空のマップを返す

    Map<String, Map<String, int>> deckDistribution = {};

    for (var card in cardRows) {
      String deckID = card['deck_id'].toString();
      deckDistribution.putIfAbsent(
          deckID, () => {'New': 0, 'Learn': 0, 'Review': 0});

      if (card['queue'] == 0) {
        deckDistribution[deckID]!['New'] =
            deckDistribution[deckID]!['New']! + 1;
      } else if (card['queue'] == 1) {
        deckDistribution[deckID]!['Learn'] =
            deckDistribution[deckID]!['Learn']! + 1;
      } else if (card['queue'] == 2) {
        deckDistribution[deckID]!['Review'] =
            deckDistribution[deckID]!['Review']! + 1;
      }
    }

    return deckDistribution;
  }

  void updateFutureCardData() {
    futureCardData = fetchAllDecksCardQueueDistribution();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners(); // ビルド後にリスナーに通知
    });
  }

  // Streamでデータを定期的に取得
  Stream<Map<String, Map<String, int>>> get cardDataStream async* {
    while (true) {
      await Future.delayed(Duration(seconds: 1)); // 定期的に更新
      yield await fetchAllDecksCardQueueDistribution(); // 新しいデータをyield
    }
  }

  Future<Map<String, int>> fetchCardQueueDistribution() async {
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

  // prepareCardAnswer関数内での使用
  Map<String, dynamic>? prepareCardAnswer(int ease) {
    // scheduler と currentCard が null でないことを確認
    if (scheduler != null && currentCard != null) {
      // currentCardをMapに変換してコピーを作成
      Map<String, dynamic> cardMap = currentCard!.toMap();

      // srs名前空間からCardクラスを呼び出す
      srs.Card currentCardCopy = srs.Card.fromMap(cardMap, currentCard!.word);

      // currentCardCopyをanswerCardで操作
      scheduler!.answerCard(currentCardCopy, ease);

      // JSON形式で保存するプロパティをまとめる
      Map<String, dynamic> cardProperties = {
        'id': currentCardCopy.id,
        'due': currentCardCopy.due,
        'crt': currentCardCopy.crt,
        'type': currentCardCopy.type,
        'queue': currentCardCopy.queue,
        'ivl': currentCardCopy.ivl,
        'factor': currentCardCopy.factor,
        'reps': currentCardCopy.reps,
        'lapses': currentCardCopy.lapses,
        'left': currentCardCopy.left,
      };

      // easeに応じたキー名を生成
      String easeKey = 'easeState$ease';

      // JSON形式に変換
      String jsonCardProperties = jsonEncode(cardProperties);

      // 計算結果を返す
      return cardProperties;
    } else {
      // scheduler か currentCard が null の場合は null を返す
      print("scheduler or currentCard is null, cannot proceed.");
      return null;
    }
  }

  String calculateTimeUntilNextReview(
      srs.Card currentCard, Map<String, dynamic> cardProperties, int ease) {
    // currentCard から type と left を取得
    int type = currentCard.type;
    int left = currentCard.left % 1000; // left を 1000 で割った余りを使用
    int ivl = cardProperties['ivl']; // ivl は cardProperties から取得

    print('Debug - card.type: $type, card.left: $left, ease: $ease, ivl: $ivl');

    // ivlが30日を超えた場合は「ヶ月」で表示
    String formatIvl(int ivl) {
      if (ivl > 30) {
        double months = ivl / 30;
        return '${months.toStringAsFixed(1)}ヶ月後'; // 小数点第一位まで「ヶ月」で表示
      } else {
        return '$ivl日後'; // 30日以下の場合はそのまま日で表示
      }
    }

    // card.type と ease に基づいて時間を計算
    if (type == 0) {
      switch (ease) {
        case 1:
          return '1分後';
        case 2:
          return '6分後';
        case 3:
          return '10分後';
        case 4:
          return formatIvl(ivl); // ivlをフォーマットして表示
      }
    } else if (type == 1) {
      if (left == 2) {
        // leftの値が 2 の場合
        switch (ease) {
          case 1:
            return '1分後';
          case 2:
            return '6分後';
          case 3:
            return '10分後';
          case 4:
            return formatIvl(ivl); // ivlをフォーマットして表示
        }
      } else if (left == 1) {
        // leftの値が 1 の場合
        switch (ease) {
          case 1:
            return '1分後';
          case 2:
            return '10分後';
          case 3:
            return '1日後';
          case 4:
            return formatIvl(ivl); // ivlをフォーマットして表示
        }
      }
    } else if (type == 2) {
      switch (ease) {
        case 1:
          return '10分後';
        case 2:
        case 3:
        case 4:
          return formatIvl(ivl); // ivlをフォーマットして表示
      }
    } else if (type == 3) {
      switch (ease) {
        case 1:
          return '10分後';
        case 2:
          return '15分後';
        case 3:
        case 4:
          return formatIvl(ivl); // ivlをフォーマットして表示
      }
    }

    // 万が一どれにも該当しない場合は "N/A" を返す
    return 'N/A';
  }

  Future<void> answerCard(Map<String, dynamic> cardProperties, int ease,
      BuildContext context, int deckID) async {
    if (scheduler != null && currentCard != null) {
      scheduler!.removeCardFromQueue(currentCard!);
      // cardPropertiesがnullでない場合、currentCardのプロパティを更新

      if (currentCard!.queue == 0) {
        deckData[deckID.toString()]!["todayNewCardsCount"] += 1;
        saveDeckData(deckData);
      }

      if (currentCard!.queue == 2) {
        deckData[deckID.toString()]!["todayReviewCardsCount"] += 1;
        saveDeckData(deckData);
      }
      if (cardProperties != null) {
        currentCard!.ivl = cardProperties['ivl'];
        currentCard!.factor = cardProperties['factor'];
        currentCard!.due = cardProperties['due'];
        currentCard!.crt = cardProperties['crt'];
        currentCard!.queue = cardProperties['queue'];
        currentCard!.type = cardProperties['type'];
        currentCard!.reps = cardProperties['reps'];
        currentCard!.lapses = cardProperties['lapses'];
        currentCard!.left = cardProperties['left'];
      }

      // カード情報を更新
      await dbHelper.updateCard(currentCard!);
      if (totalCardCountByDeckID(deckID) == 0) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => OtsukareScreen()));
      }
      currentCard = await getCard(deckID);
      notifyListeners();
    }
  }

  Future<srs.Card?> getCard(int deckID) async {
    return await scheduler?.getCard(deckID, deckData); // await で非同期の結果を待つ
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

  Future<void> updateWordInCurrentCard(
      String word,
      String pronunciation,
      String mainMeaning,
      String subMeaning,
      String sentence,
      String sentenceJp,
      String englishDefinition,
      String etymology,
      String memo,
      String? imageUrl) async {
    print('updateWordを発動しました');
    if (currentCard != null) {
      currentCard!.word.word = word;
      currentCard!.word.pronunciation =
          pronunciation.isNotEmpty ? pronunciation : null;
      currentCard!.word.mainMeaning = mainMeaning;
      currentCard!.word.subMeaning = subMeaning.isNotEmpty ? subMeaning : null;
      currentCard!.word.sentence = sentence;
      currentCard!.word.sentenceJp = sentenceJp;
      currentCard!.word.englishDefinition = englishDefinition;
      currentCard!.word.etymology = etymology;
      currentCard!.word.memo = memo;
      currentCard!.word.imageUrl = imageUrl;

      // 非同期処理を待機
      await updateCurrentCard();
    } else {
      print('currentCardがnullだったのでupdateCurrentCardを発動しませんでした');
    }
    return;
  }

  // currentCardをデータベースに保存
  Future<void> updateCurrentCard() async {
    print('updateCurrentCardを発動しました');
    if (currentCard != null) {
      await dbHelper.updateWord(currentCard!.word);
      await dbHelper.updateCard(currentCard!);
      notifyListeners();
    }
  }

  Future<void> initialAssignDueToNewCard(int deckID) async {
    await scheduler!.assignDueToNewCardByDeckID(
        deckID, dbHelper.updateCard, deckData); // updateCardをコールバックとして渡す
    scheduler!.fillNew(alwaysRun: true);
  }

  // ダウンロード済みのデッキリストを取得する関数
  List<Map<String, dynamic>> getAvailableDecks() {
    return deckData.values
        .where((deck) => deck["isDownloaded"] != DownloadStatus.notDownloaded)
        .toList();
  }

  // 最初のダウンロード済みデッキのdeckIDを取得する関数
  int? getFirstDeckID(List<Map<String, dynamic>> availableDecks) {
    return int.tryParse(availableDecks.first['deckID']);
  }

  // カードIDを指定してカードを取得
  Future<void> fetchCardById(int cardId) async {
    // データベースからカードを取得
    currentCard = await dbHelper.queryCardById(cardId);

    // 取得できた場合のみ通知
    if (currentCard != null) {
      notifyListeners();
    } else {
      print('Card not found for ID: $cardId');
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
