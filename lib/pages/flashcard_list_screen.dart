import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:kokotan/Algorithm/srs.dart' as srs;
import 'package:kokotan/db/database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class FlashcardListScreen extends StatefulWidget {
  @override
  _FlashcardListScreenState createState() => _FlashcardListScreenState();
}

class _FlashcardListScreenState extends State<FlashcardListScreen> {
  List<srs.Word> _words = [];
  List<srs.Card> _cards = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  List<srs.Word> _searchResults = [];
  double _downloadProgress = 0.0;
  bool _dataFetched = false;

  // TODO: この辺の処理はDataViewModelに移動する
  Future<void> _fetchWords() async {
    print('Fetching words...');
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

    setState(() {
      _words = words;
      _cards = cards;
      _searchResults = words;
      _dataFetched = words.isNotEmpty;
      _isLoading = false;
    });
  }

  Future<void> _downloadAndImportExcel() async {
    setState(() {
      _isLoading = true;
      _downloadProgress = 0.0;
    });

    const url =
        'https://kokomirai.jp/wp-content/uploads/2024/06/dev_kokotan_list.xlsx';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/dev_kokotan_list.xlsx');
      await file.writeAsBytes(bytes);

      await _importExcelToDatabase(file);

      setState(() {
        _isLoading = false;
      });

      _fetchWords();
      print("Excel downloaded and imported successfully！");
    } else {
      setState(() {
        _isLoading = false;
      });
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

  void _search(String query) {
    final results = _words.where((word) {
      final wordStr = word.word.toLowerCase();
      final input = query.toLowerCase();
      return wordStr.contains(input);
    }).toList();

    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flashcards'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _downloadAndImportExcel,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LinearProgressIndicator(value: _downloadProgress),
                  const SizedBox(height: 20),
                  const Text('Downloading...'),
                ],
              ),
            )
          : Column(
              children: [
                if (_dataFetched)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search',
                        suffixIcon: IconButton(
                          icon: Icon(Icons.search),
                          onPressed: () {
                            _search(_searchController.text);
                          },
                        ),
                      ),
                      onChanged: _search,
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final word = _searchResults[index];
                      final card = _cards.firstWhere(
                        (c) => c.word.id == word.id,
                        orElse: () => srs.Card(srs.Word(
                          id: 0,
                          word: '',
                          mainMeaning: '',
                          subMeaning: '',
                          sentence: '',
                          sentenceJp: '',
                        )),
                      );

                      return ListTile(
                        title: Text(word.word),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Main Meaning: ${word.mainMeaning}'),
                            Text('Sub Meaning: ${word.subMeaning}'),
                            Text('Sentence: ${word.sentence}'),
                            Text('Sentence JP: ${word.sentenceJp}'),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Card ID: ${card.id}'),
                                Text(
                                    'Due: ${DateTime.fromMillisecondsSinceEpoch(card.due)}'),
                                Text('Interval: ${card.ivl}'),
                                Text('Factor: ${card.factor}'),
                                Text('Repetitions: ${card.reps}'),
                                Text('Lapses: ${card.lapses}'),
                              ],
                            ),
                          ],
                        ),
                        onTap: () {
                          // Implement navigation to card details if needed
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
