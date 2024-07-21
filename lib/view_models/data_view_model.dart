import 'package:flutter/material.dart';
import 'package:kokotan/Algorithm/srs.dart' as srs;
import 'package:kokotan/db/database_helper.dart';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DataViewModel extends ChangeNotifier {
  List<srs.Word> _words = [];
  List<srs.Card> _cards = [];
  bool _isLoading = false;
  List<srs.Word> _searchResults = [];
  bool _dataFetched = false;
  srs.Scheduler? scheduler;
  srs.Card? currentCard;

  DataViewModel() {
    _loadDataFetchedFlag();
  }

  Future<void> initializeData() async {
    await fetchWordsAndInitializeScheduler();
  }

  List<srs.Word> get words => _words;
  List<srs.Card> get cards => _cards;
  bool get isLoading => _isLoading;
  List<srs.Word> get searchResults => _searchResults;
  bool get dataFetched => _dataFetched;
  srs.Card? get card => currentCard;
  srs.Word? get currentWord => currentCard?.word;

  int get newCardCount => _cards.where((card) => card.queue == 0).length;
  int get learningCardCount => _cards.where((card) => card.queue == 1).length;
  int get reviewCardCount => _cards.where((card) => card.queue == 2).length;

  Future<void> _loadDataFetchedFlag() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _dataFetched = prefs.getBool('dataFetched') ?? false;
    notifyListeners();
  }

  Future<void> _saveDataFetchedFlag(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dataFetched', value);
  }

  Future<void> downloadAndImportExcel() async {
    _isLoading = true;
    notifyListeners();

    const url =
        'https://kokomirai.jp/wp-content/uploads/2024/06/dev_kokotan_list.xlsx';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/dev_kokotan_list.xlsx');
      await file.writeAsBytes(bytes);

      await _importExcelToDatabase(file);
      await fetchWordsAndInitializeScheduler();
      print("Excel downloaded and imported successfully！");

      _dataFetched = true;
      await _saveDataFetchedFlag(true);
    } else {
      _isLoading = false;
      notifyListeners();
      print('Error downloading file: ${response.statusCode}');
    }
  }

  Future<void> _importExcelToDatabase(File file) async {
    final dbHelper = DatabaseHelper.instance;

    try {
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table];
        for (var row in sheet!.rows) {
          if (row[0] == 'id') continue; // Skip the header row

          srs.Word word = srs.Word(
            id: row.length > 0
                ? (int.tryParse(row[0]?.value.toString() ?? '') ?? 0)
                : 0,
            word: row.length > 1 ? (row[1]?.value?.toString() ?? '') : '',
            mainMeaning:
                row.length > 2 ? (row[2]?.value?.toString() ?? '') : '',
            subMeaning: row.length > 3 ? (row[3]?.value?.toString() ?? '') : '',
            sentence: row.length > 4 ? (row[4]?.value?.toString() ?? '') : '',
            sentenceJp: row.length > 5 ? (row[5]?.value?.toString() ?? '') : '',
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

          print('Inserted word: ${word.word}, card ID: ${card.id}');
        }
      }
      print('Excel data imported successfully');
    } catch (e) {
      print('Error importing Excel data: $e');
    }
  }

  Future<void> fetchWordsAndInitializeScheduler() async {
    print('Fetching words and initializing scheduler...');
    _isLoading = true;
    notifyListeners();

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
    _dataFetched = _words.isNotEmpty;

    // コレクションとデッキを初期化
    var collection = srs.Collection();
    var deckName = 'Default Deck';
    collection.addDeck(deckName);

    for (var card in cards) {
      collection.addCardToDeck(deckName, card);
    }

    scheduler = srs.Scheduler(collection);
    currentCard = scheduler!.getCard();

    _isLoading = false;
    notifyListeners();
  }

  void answerCard(int ease) async {
    if (scheduler != null && currentCard != null) {
      scheduler!.answerCard(currentCard!, ease);

      // カード情報を更新
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.updateCard(currentCard!);

      currentCard = scheduler!.getCard();
      notifyListeners();
    }
  }

  srs.Card? getCard() {
    return scheduler?.getCard();
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
