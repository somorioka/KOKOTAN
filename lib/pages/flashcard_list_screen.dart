import 'package:flutter/material.dart';
import 'package:kokotan/db/database_helper.dart';

class FlashcardListScreen extends StatefulWidget {
  @override
  _FlashcardListScreenState createState() => _FlashcardListScreenState();
}

class _FlashcardListScreenState extends State<FlashcardListScreen> {
  List<Map<String, dynamic>> _cards = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

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
      print('Fetched ${_cards.length} cards');
      _isLoading = false;
    });
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
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
