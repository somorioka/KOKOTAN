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
    final directory = await getApplicationDocumentsDirectory();
    int wordCount = 0;

    try {
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      final db = await dbHelper.database; // データベースをawaitで取得する

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        for (var row in sheet!.rows) {
          if (row[0]?.value.toString() == 'wordid') {
            continue; // ヘッダー行をスキップ
          }

          int wordId = int.tryParse(row[0]?.value.toString() ?? '') ?? 0;

          // 音声ファイルのパスを生成
          String wordVoicePath = '${directory.path}/${row[0]?.value}_word.mp3';
          String sentenceVoicePath =
              '${directory.path}/${row[0]?.value}_sentence.mp3';

          // 音声ファイルの存在確認
          File wordVoiceFile = File(wordVoicePath);
          File sentenceVoiceFile = File(sentenceVoicePath);

          print('このwordIdのファイルをチェックします: $wordId');

          // ファイルの存在を確認
          bool wordFileExists = wordVoiceFile.existsSync();
          bool sentenceFileExists = sentenceVoiceFile.existsSync();

          // ファイルのサイズも確認
          int wordFileSize = wordFileExists ? wordVoiceFile.lengthSync() : 0;
          int sentenceFileSize =
              sentenceFileExists ? sentenceVoiceFile.lengthSync() : 0;

          // データベースにその `wordId` が存在するか確認
          bool wordExists = await dbHelper.doesWordExist(wordId);

          // トランザクションを使用してデータベース操作を行う
          await db.transaction((txn) async {
            // 1. WordIDが存在しない場合、新規にデータを挿入
            if (!wordExists) {
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

              // 新しい単語データを挿入
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

              await txn.insert(DatabaseHelper.wordTable,
                  word.toMap()); // クラス名を使用して静的メンバーにアクセス
              // カードを作成し挿入
              srs.Card card = srs.Card(word);
              await txn.insert(
                  DatabaseHelper.cardTable, card.toMap()); // クラス名を使用
            } else {
              // 2. WordIDが存在し、音声ファイルがない場合、音声ファイルのみ更新
              if (!wordFileExists ||
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
                      wordVoiceUrl,
                      '${row[0]?.value}_word.mp3',
                      directory.path);
                }

                if (sentenceVoiceUrl.isNotEmpty) {
                  sentenceVoicePath = await _downloadAndSaveFileWithRetry(
                      sentenceVoiceUrl,
                      '${row[0]?.value}_sentence.mp3',
                      directory.path);
                }

                // 音声ファイルのパスを更新
                await txn.update(
                    DatabaseHelper.wordTable,
                    {
                      // クラス名を使用
                      'word_voice': wordVoicePath,
                      'sentence_voice': sentenceVoicePath,
                    },
                    where: '${DatabaseHelper.columnId} = ?',
                    whereArgs: [wordId]); // クラス名を使用
              } else {
                // 3. WordIDも音声ファイルも存在する場合はスキップ
                print('単語も音声ファイルも既に存在するため、スキップします:$wordId');
                return;
              }
            }

          wordCount++;
            print('Word count: $wordCount, Limit: $limit');

            // 進捗ログ
            print('進捗: ${(wordCount / limit * 100).toStringAsFixed(2)}%');

          _downloadProgress = wordCount / limit;
          notifyListeners();

            if (wordCount >= limit) {
              print('Limit reached. Exiting transaction.');
              return; // トランザクション内でreturnし、外側のループも終了させる
            }
          });

          // limit に達したら外側の for ループも終了
          if (wordCount >= limit) {
            break;
        }
        }

        // limit に達したらテーブルのループを終了
        if (wordCount >= limit) {
          break;
        }
      }
      print('_importExcelToDatabaseが完了しました');
    } catch (e) {
      print('Error importing Excel data: $e');
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

  Future<void> reDownloadAndImportExcel() async {
    print('reDownloadAndImportExcelを発動しています');
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/sa_ver01.xlsx');
    // データダウンロードフラグをfalseに設定
    _isAllDataDownloaded = false;

    // フラグの値をSharedPreferencesに保存
    await _saveAllDataDownloadedFlag(_isAllDataDownloaded);

    // すべてのデータをインポートする
    downloadRemainingDataInBackground();

    print('reDownloadAndImportExcelが完了しました');
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

  Future<void> downloadRemainingDataInBackground() async {
    if (_isAllDataDownloaded) {
      print('全てのデータがダウンロードされています');
      return;
    }

    print('残りのデータをバックグラウンドでダウンロードします');

    // すべてのデータをインポートするように設定 (limit=無制限)
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/sa_ver01.xlsx');

    if (await file.exists()) {
      // 既に存在するExcelファイルからデータを取り込む
      await _importExcelToDatabase(file, limit: 10000);

      print('全てのデータがダウンロードされました');

      // ここでダウンロードが完了してからフラグをtrueに設定
      await _saveAllDataDownloadedFlag(true); // ここでフラグを保存
      _isAllDataDownloaded = true; // ここでフラグを更新
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
      BuildContext context) async {
    if (scheduler != null && currentCard != null) {
      scheduler!.removeCardFromQueue(currentCard!);
      // cardPropertiesがnullでない場合、currentCardのプロパティを更新
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
