import 'package:flutter/material.dart';
import 'package:kokotan/pages/flashcard_screen.dart';
import 'package:kokotan/view_models/data_view_model.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'title': 'ベーシック',
        'subtitle': 'ターゲット1400, システム英単語basicレベル',
        'icon': Icons.cloud_download,
      },
      {
        'title': 'スタンダードA',
        'subtitle': 'ターゲット1900, システム英単語 前半レベル',
        'icon': Icons.cloud_download,
      },
      {
        'title': 'スタンダードB',
        'subtitle': 'ターゲット1900, システム英単語 後半レベル',
        'icon': Icons.cloud_download,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('ココタン'),
      ),
      body: Column(
        children: [
          Container(
              height: 200,
              width: 200,
              child: Image.asset('assets/images/humor_top.png')),
          Expanded(
            child: Consumer<DataViewModel>(
              builder: (context, viewModel, child) {
                return ListView.builder(
                  padding: EdgeInsets.all(8.0),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        trailing: viewModel.isLoading
                            ? Icon(Icons.hourglass_empty)
                            : (viewModel.dataFetched
                                ? Icon(Icons.check_circle)
                                : Icon(Icons.cloud_download)),
                        title: Text(item['title'] as String),
                        subtitle: Text(item['subtitle'] as String),
                        onTap: () {
                          if (viewModel.dataFetched) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FlashCardScreen(),
                              ),
                            );
                          } else {
                            viewModel.downloadAndImportExcel();
                          }
                        },
                      ),
                    );
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
