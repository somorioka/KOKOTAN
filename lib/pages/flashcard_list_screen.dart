import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:kokotan/db/database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class FlashcardListScreen extends StatefulWidget {
  @override
  _FlashcardListScreenState createState() => _FlashcardListScreenState();
}

class _FlashcardListScreenState extends State<FlashcardListScreen> {
  List<Map<String, dynamic>> _cards = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  double _downloadProgress = 0.0;
  bool _dataFetched = false; // データが最初にフェッチされたかどうかを示すフラグ

  @override
  void initState() {
    super.initState();
    _fetchCards();
  }

  Future<void> _fetchCards() async {
    print('Fetching cards...');
    final dbHelper = DatabaseHelper.instance;
    final cards = await dbHelper.queryAllRows();
    setState(() {
      _cards = cards;
      _searchResults = cards;
      _dataFetched = cards.isNotEmpty;
      _isLoading = false;
    });
  }

  Future<void> _downloadAndImportExcel() async {
    setState(() {
      _isLoading = true;
      _downloadProgress = 0.0;
    });

    const url =
        'https://kokomirai.jp/wp-content/uploads/2024/06/dev_kokotan_list.xlsx'; // インターネット上のExcelファイルのURL
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

      _fetchCards(); // Fetch the newly imported cards from the database
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

          Map<String, dynamic> card = {
            'id': row.length > 0
                ? int.tryParse(row[0]?.value.toString() ?? '')
                : null,
            'word': row.length > 1 ? row[1]?.value.toString() : '',
            'main_meaning': row.length > 2 ? row[2]?.value.toString() : '',
            'sub_meaning': row.length > 3 ? row[3]?.value.toString() : '',
            'sentence': row.length > 4 ? row[4]?.value.toString() : '',
            'sentence_jp': row.length > 5 ? row[5]?.value.toString() : ''
          };

          if (card['id'] == null ||
              card['word'] == '' ||
              card['main_meaning'] == '' ||
              card['sentence'] == '' ||
              card['sentence_jp'] == '') {
            continue;
          }

          await dbHelper.insert(card);
          print('Inserted card: $card'); // デバッグメッセージ追加
        }
      }
      print('Excel data imported successfully');
    } catch (e) {
      print('Error importing Excel data: $e');
    }
  }

  void _search(String query) {
    final results = _cards.where((card) {
      final word = card['word'].toString().toLowerCase();
      final input = query.toLowerCase();
      return word.contains(input);
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
                      final card = _searchResults[index];
                      return ListTile(
                        title: Text(card['word']),
                        subtitle: Text(card['main_meaning']),
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
