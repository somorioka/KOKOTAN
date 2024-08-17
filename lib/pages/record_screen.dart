import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kokotan/view_models/data_view_model.dart';
import 'package:provider/provider.dart';

class RecordScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('記録'),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: Provider.of<DataViewModel>(context, listen: false)
            .fetchCardQueueDistribution(),
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
                  padding: const EdgeInsets.all(16.0), // 余白を追加
                  child: AspectRatio(
                    aspectRatio: 1.3, // アスペクト比を設定して高さを調整
                    child: PieChart(
                      PieChartData(
                        sections: showingSections(cardData),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20), // チャートとテキストの間に余白を追加
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('未学習: ${cardData['New']} 枚',
                          style: TextStyle(fontSize: 16)),
                      Text('覚え中: ${cardData['Learn']} 枚',
                          style: TextStyle(fontSize: 16)),
                      Text('復習: ${cardData['Review']} 枚',
                          style: TextStyle(fontSize: 16)),
                    ],
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
            color: Colors.orange,
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
