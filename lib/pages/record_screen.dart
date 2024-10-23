import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kokotan/view_models/data_view_model.dart';
import 'package:provider/provider.dart';

class RecordScreen extends StatefulWidget {
  @override
  _RecordScreenState createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  Future<Map<String, int>>? _futureCardData;

  @override
  void initState() {
    super.initState();
    _fetchData(); // 初期化時にデータを取得
  }

  void _fetchData() {
    setState(() {
      _futureCardData = Provider.of<DataViewModel>(context, listen: false)
          .fetchCardQueueDistribution();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DataViewModel>(context); // viewModelを取得

    return Scaffold(
      appBar: AppBar(
        title: Text('記録'),
        centerTitle: true, // タイトルを中央に配置
        actions: [
          IconButton(
            icon: Icon(Icons.refresh), // 更新ボタン
            onPressed: _fetchData, // ボタンを押したらデータを再フェッチ
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: launchHelpURL,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _futureCardData, // Futureを参照
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('データがありません'));
          } else {
            final cardData = snapshot.data!;
            return Column(
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
                        sections: showingSections(cardData),
                              centerSpaceRadius: 100, // 中央スペースを調整
                    ),
                  ),
                          Positioned(
                            child: Text(
                              'スタンダードA',
                              style: TextStyle(
                                  fontFamily: 'ZenMaruGothic',
                                  fontWeight: FontWeight.w700, // Bold
                                  fontSize: 25,
                                  color: Color(0xFF333333)),
                            ),
                          ),
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
                        _buildStatusColumn('新規', cardData['New']!, Colors.blue),
                        _buildStatusColumn(
                            '学習中', cardData['Learn']!, Colors.red),
                        _buildStatusColumn(
                            '復習', cardData['Review']!, Colors.green),
                    ],
                  ),
                ),
                ),
                const SizedBox(height: 24),
                if (!viewModel.isAllDataDownloaded)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'ダウンロード中…\n右上の更新ボタンを押すと反映されるよ',
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
            );
          }
        },
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
