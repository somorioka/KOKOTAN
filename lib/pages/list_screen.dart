import 'package:flutter/material.dart';
import 'package:kokotan/Algorithm/srs.dart' as srs;
import 'package:kokotan/view_models/data_view_model.dart';
import 'package:provider/provider.dart';

class ListScreen extends StatefulWidget {
  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flashcards'),
      ),
      body: Consumer<DataViewModel>(
        builder: (context, viewModel, child) {
          return viewModel.isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      const Text('Downloading...'),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (viewModel.dataFetched)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Search',
                            suffixIcon: IconButton(
                              icon: Icon(Icons.search),
                              onPressed: () {},
                            ),
                          ),
                          onChanged: (query) {
                            viewModel.search(query);
                          },
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: viewModel.searchResults.length,
                        itemBuilder: (context, index) {
                          final word = viewModel.searchResults[index];
                          final card = viewModel.cards.firstWhere(
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
                );
        },
      ),
    );
  }
}
