import 'package:flutter/material.dart';
import 'package:kokotan/pages/flashcard_screen.dart';
import 'package:kokotan/view_models/data_view_model.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'title': 'ベーシック (準備中)',
        'subtitle': 'ターゲット1400, システム英単語basicレベル',
        'icon': Icons.chevron_right,
        'color': const Color.fromARGB(255, 236, 236, 236),
      },
      {
        'title': 'スタンダードA',
        'subtitle': 'ターゲット1900, システム英単語 前半レベル',
        'icon': Icons.chevron_right,
        'color': Colors.white,
      },
      {
        'title': 'スタンダードB (準備中)',
        'subtitle': 'ターゲット1900, システム英単語 後半レベル',
        'icon': Icons.chevron_right,
        'color': const Color.fromARGB(255, 236, 236, 236),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
      ),
      body: Consumer<DataViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            // isLoadingがtrueの場合、ダウンロード中メッセージを表示
            return Center(
              child: Text(
                '単語帳データをダウンロードしています',
                style: TextStyle(fontSize: 18),
              ),
            );
          } else {
            // isLoadingがfalseの場合、リストを表示
            return Column(
              children: [
                Container(
                    height: 241,
                    width: 361,
                    child: Image.asset('assets/images/home_humor1.png')),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(8.0),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        child: ListTile(
                          tileColor: item['color'] as Color,
                          trailing: Icon(item['icon'] as IconData),
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
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
