import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kokotan/model/deck_list.dart';
import 'package:kokotan/view_models/data_view_model.dart';
import 'package:provider/provider.dart';

class RecordScreen extends StatefulWidget {
  @override
  _RecordScreenState createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  int? _selectedDeckID;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<DataViewModel>(context, listen: false);
    final availableDecks = viewModel.getAvailableDecks();
    // selectedDeckIDがnullの時だけ初期化
    _selectedDeckID = viewModel.getFirstDeckID(availableDecks) ?? 0;
    fetchRecordData(); // 初期化時にデータを取得
  }

  void fetchRecordData() {
    setState(() {
      Provider.of<DataViewModel>(context, listen: false).updateFutureCardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final viewModel = Provider.of<DataViewModel>(context); // viewModelを取得
    final availableDecks = viewModel.getAvailableDecks(); // 利用可能なデッキを取得
    return DefaultTabController(
      length: availableDecks.length, // デッキ数に応じてタブを設定
      child: Scaffold(
        appBar: AppBar(
          title: Text('学習状況'),
          automaticallyImplyLeading: false, // 左上の戻るボタンを非表示
          centerTitle: true, // タイトルを中央に配置
          actions: [
            // IconButton(
            //   icon: Icon(Icons.refresh), // 更新ボタン
            //   onPressed: fetchRecordData, // ボタンを押したらデータを再フェッチ
            // ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: launchHelpURL,
            ),
          ],
          bottom: TabBar(
            isScrollable: true, // 横スクロール可能に設定
            labelColor: const Color(0xFF333333), // 選択されたタブのテキスト色
            unselectedLabelColor: Colors.grey, // 非選択タブのテキスト色
            indicatorColor: Color.fromARGB(255, 60, 177, 180), // タブ下部のインジケータの色
            indicatorWeight: 4.0, // インジケータの太さ
            indicatorSize: TabBarIndicatorSize.label, // インジケータの幅（タブラベルに合わせる）
            labelStyle: TextStyle(
              fontSize: 18, // 選択されたタブのフォントサイズ
              fontWeight: FontWeight.w700, // フォントの太さ
              fontFamily: 'ZenMaruGothic', // フォントファミリー
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 14, // 非選択タブのフォントサイズ
              fontWeight: FontWeight.w500,
              fontFamily: 'ZenMaruGothic',
            ),
            onTap: (index) {
              setState(() {
                if (index < availableDecks.length) {
                  _selectedDeckID = index + 1;
                }
              });
            },

            tabs: availableDecks
                .map((deck) => Tab(text: deck["deckName"]))
                .toList(),
          ),
        ),
        body: FutureBuilder<Map<String, Map<String, int>>>(
          future: viewModel.fetchAllDecksCardQueueDistribution(), // 直接呼び出し
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // 縦方向の中央
                  crossAxisAlignment: CrossAxisAlignment.center, // 横方向の中央
                  children: [
                    CircularProgressIndicator(), // 読み込み中の表示
                    SizedBox(height: 16), // アイテム間のスペース
                    Text(
                      'データをダウンロードしています…',
                      style: TextStyle(
                        fontFamily: 'ZenMaruGothic',
                        fontWeight: FontWeight.w700, // Bold
                        fontSize: 16,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Text("エラーが発生しました: ${snapshot.error}"); // エラー表示
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text("データがありません"); // データがない場合の表示
            } else {
              final cardData = snapshot.data ?? {}; // snapshot.dataからデータを取得
              return SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 24.0),
                      child: AspectRatio(
                          aspectRatio: 1.0, // グラフを大きく
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  sections: showingSections(
                                      cardData[_selectedDeckID.toString()]!),
                                  centerSpaceRadius: 100, // 中央スペースを調整
                                ),
                              ),
                              // Positioned(
                              //   child: Text(
                              //     viewModel.deckData[_selectedDeckID.toString()]![
                              //         'deckName'],
                              //     style: TextStyle(
                              //         fontFamily: 'ZenMaruGothic',
                              //         fontWeight: FontWeight.w700, // Bold
                              //         fontSize: 25,
                              //         color: Color(0xFF333333)),
                              //   ),
                              // ),
                            ],
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatusColumn(
                                '新規',
                                cardData[_selectedDeckID.toString()]!['New']!,
                                Colors.blue),
                            _buildStatusColumn(
                                '学習中',
                                cardData[_selectedDeckID.toString()]!['Learn']!,
                                Colors.red),
                            _buildStatusColumn(
                                '復習',
                                cardData[_selectedDeckID.toString()]![
                                    'Review']!,
                                Colors.green),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (viewModel.deckData[_selectedDeckID.toString()]![
                            'isDownloaded'] !=
                        DownloadStatus.downloaded)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'ダウンロード中…',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.redAccent,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections(Map<String, int> cardData) {
    return List.generate(3, (i) {
      final double fontSize = 16;
      final double radius = 50;

      switch (i) {
        case 0:
          return PieChartSectionData(
            color: Colors.blue,
            value: cardData['New']!.toDouble(),
            title: '${cardData['New']}',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xffffffff),
            ),
          );
        case 1:
          return PieChartSectionData(
            color: Colors.red,
            value: cardData['Learn']!.toDouble(),
            title: '${cardData['Learn']}',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xffffffff),
            ),
          );
        case 2:
          return PieChartSectionData(
            color: Colors.green,
            value: cardData['Review']!.toDouble(),
            title: '${cardData['Review']}',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: const Color(0xffffffff),
            ),
          );
        default:
          throw Error();
      }
    });
  }
}

Widget _buildStatusColumn(String label, int count, Color color) {
  return Column(
    children: [
      Text(
        label,
        style: TextStyle(
            fontFamily: 'ZenMaruGothic',
            fontWeight: FontWeight.w700, // Bold
            fontSize: 20,
            color: Color(0xFF333333)),
      ),
      SizedBox(height: 8),
      Text(
        '$count 枚',
        style: TextStyle(
          fontFamily: 'ZenMaruGothic',
          fontWeight: FontWeight.w700, // Bold
          fontSize: 20,
          color: color,
        ),
      ),
    ],
  );
}
