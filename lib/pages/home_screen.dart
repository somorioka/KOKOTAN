import 'package:flutter/material.dart';
import 'package:kokotan/pages/flashcard_screen.dart';
import 'package:kokotan/view_models/data_view_model.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'title': 'スタンダードA',
        'subtitle': 'ターゲット1900, システム英単語 前半レベル',
        'icon': Icons.chevron_right,
        'color': Color.fromARGB(255, 251, 251, 251),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: Consumer<DataViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '単語帳データをダウンロードしています',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                LinearProgressIndicator(
                  value: viewModel.downloadProgress, // プログレスバーを表示
                ),
                const SizedBox(height: 20),
                Text("${(viewModel.downloadProgress * 100).toInt()}%"),
              ],
            );
          } else {
            return Column(
              children: [
                Container(
                    height: 241,
                    width: 361,
                    child: Image.asset('assets/images/home_humor1.png')),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FlashCardScreen(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                            1, 240, 240, 240), // ボタンの背景色を指定
                        foregroundColor: Colors.white, // テキストやアイコンの色を指定
                      ),
                      onPressed: () {},
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add),
                          SizedBox(width: 8),
                          Text("単語帳を追加"),
                        ],
                      )),
                ),
                const SizedBox(height: 16),
              ],
            );
          }
        },
      ),
    );
  }
}
