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
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DataViewModel>(context, listen: false);

    return FutureBuilder(
      future: viewModel.initializeDeckData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("エラーが発生しました: ${snapshot.error}"));
        } else {
          final availableDecks = viewModel.getAvailableDecks();
          // 初期のデッキIDを設定
          if (_selectedDeckID == null && availableDecks.isNotEmpty) {
            _selectedDeckID = viewModel.getFirstDeckID(availableDecks);
          }
          return _buildMainContent(context, availableDecks, viewModel);
        }
      },
    );
  }

  Widget _buildMainContent(BuildContext context,
      List<Map<String, dynamic>> availableDecks, DataViewModel viewModel) {
    return DefaultTabController(
      length: availableDecks.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('学習状況'),
          automaticallyImplyLeading: false,
          centerTitle: true,
          actions: [
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
                _selectedDeckID = index + 1;
              });
            },
            tabs: availableDecks
                .map((deck) => Tab(text: deck["deckName"]))
                .toList(),
          ),
        ),
        body: _selectedDeckID != null
            ? FutureBuilder<Map<String, Map<String, int>>>(
                future: viewModel.fetchAllDecksCardQueueDistribution(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'データをダウンロードしています…',
                            style: TextStyle(
                              fontFamily: 'ZenMaruGothic',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text("エラーが発生しました: ${snapshot.error}");
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text("データがありません");
                  } else {
                    final cardData = snapshot.data ?? {};
                    return _buildCardDataContent(context, cardData, viewModel);
                  }
                },
              )
            : Center(child: Text("デッキが選択されていません")),
      ),
    );
  }

  Widget _buildCardDataContent(BuildContext context,
      Map<String, Map<String, int>> cardData, DataViewModel viewModel) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: showingSections(
                          cardData[_selectedDeckID.toString()]!),
                      centerSpaceRadius: 100,
                    ),
                  ),
                ],
              ),
            ),
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
                      cardData[_selectedDeckID.toString()]!['Review']!,
                      Colors.green),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (viewModel.deckData[_selectedDeckID.toString()]!['isDownloaded'] !=
              DownloadStatus.downloaded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'データをダウンロード中…',
                style: TextStyle(
                    fontFamily: 'ZenMaruGothic',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
        ],
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

  Widget _buildStatusColumn(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
              fontFamily: 'ZenMaruGothic',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF333333)),
        ),
        SizedBox(height: 8),
        Text(
          '$count 枚',
          style: TextStyle(
            fontFamily: 'ZenMaruGothic',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: color,
          ),
        ),
      ],
    );
  }
}
