import 'package:flutter/material.dart';
import 'package:kokotan/Algorithm/srs.dart' as srs;
import 'package:kokotan/db/database_helper.dart';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class DataViewModel extends ChangeNotifier {
  List<srs.Word> _words = [];
  List<srs.Card> _cards = [];
  bool _isLoading = false;
  List<srs.Word> _searchResults = [];
  bool _dataFetched = false;

  List<srs.Word> get words => _words;
  List<srs.Card> get cards => _cards;
  bool get isLoading => _isLoading;
  List<srs.Word> get searchResults => _searchResults;
  bool get dataFetched => _dataFetched;

  Future<void> fetchWords() async {
    print('Fetching words...');
    final dbHelper = DatabaseHelper.instance;
    final wordRows = await dbHelper.queryAllWords();
    final cardRows = await dbHelper.queryAllCards();

    _words = wordRows.map((row) => srs.Word.fromMap(row)).toList();
    _cards = cardRows.map((row) {
      int wordId = row['word_id'];
      srs.Word word = _words.firstWhere((w) => w.id == wordId);
      return srs.Card.fromMap(row, word);
    }).toList();

    _searchResults = _words;
    _dataFetched = _words.isNotEmpty;
    _isLoading = false;
    notifyListeners();
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

      fetchWords();
      print("Excel downloaded and imported successfully！");
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
