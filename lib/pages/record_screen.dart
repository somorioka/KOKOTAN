import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kokotan/model/deck_list.dart';
import 'package:kokotan/view_models/data_view_model.dart';
import 'package:provider/provider.dart';

class RecordScreen extends StatefulWidget {
  @override
  _RecordScreenState createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen>
    with TickerProviderStateMixin {
  int? _selectedDeckID;
  TabController? _tabController;
  Map<String, Map<String, int>>? _cardData;
  bool _isLoading = true;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final viewModel = Provider.of<DataViewModel>(context, listen: false);
      _initializeData(viewModel);
      _isInitialized = true;
    }
  }

  void _initializeData(DataViewModel viewModel) async {
    try {
      print('Initializing data...');
      await viewModel.initializeDeckData();
      final availableDecks = viewModel.getAvailableDecks();

      if (availableDecks.isNotEmpty) {
        print('Available decks: ${availableDecks.length}');
        _selectedDeckID = viewModel.getFirstDeckID(availableDecks);
        _tabController = TabController(
          length: availableDecks.length,
          vsync: this,
        );
        _tabController!.addListener(() {
          if (!_tabController!.indexIsChanging) {
            setState(() {
              _selectedDeckID =
                  int.parse(availableDecks[_tabController!.index]['deckID']);
            });
          }
        });

        // カードデータの取得
        final cardData = await viewModel.fetchAllDecksCardQueueDistribution();

        setState(() {
          _cardData = cardData;
          _isLoading = false;
        });
      } else {
        print('No available decks');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _initializeData: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DataViewModel>(context);
    final availableDecks = viewModel.getAvailableDecks();

    if (_isLoading ||
        _tabController == null ||
        _selectedDeckID == null ||
        _cardData == null) {
      // ローディング中
      return Scaffold(
        appBar: AppBar(
          title: Text('学習状況'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
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
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF333333),
          unselectedLabelColor: Colors.grey,
          indicatorColor: Color.fromARGB(255, 60, 177, 180),
          indicatorWeight: 4.0,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'ZenMaruGothic',
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'ZenMaruGothic',
          ),
          tabs: availableDecks
              .map((deck) => Tab(text: deck["deckName"]))
              .toList(),
        ),
      ),
      body: _buildCardDataContent(context, _cardData!, viewModel),
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
                      startDegreeOffset: -90, // ここで12時スタートに調整
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
                'データをダウンロード中…\nアプリを開き直すと更新されます',
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
