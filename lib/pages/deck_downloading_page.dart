import 'package:flutter/material.dart';
import 'package:kokotan/view_models/data_view_model.dart';
import 'package:provider/provider.dart';
import 'package:kokotan/pages/top_page.dart'; // TopPageのパスを指定

class DownloadProgressPage extends StatefulWidget {
  final int deckID; // deckIDを受け取るプロパティを追加

  DownloadProgressPage({Key? key, required this.deckID})
      : super(key: key); // コンストラクタでdeckIDを受け取る

  @override
  _DownloadProgressPageState createState() => _DownloadProgressPageState();
}

class _DownloadProgressPageState extends State<DownloadProgressPage> {
  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  // ダウンロードを開始して、完了時にTopPageへ遷移
  void _startDownload() async {
    final viewModel = Provider.of<DataViewModel>(context, listen: false);
    await viewModel.downloadInitialData();
    await viewModel.initialAssignDueToNewCard(widget.deckID);
    await viewModel.fetchWordsAndInitializeScheduler();
    viewModel.downloadRemainingData();

    // ダウンロード完了後、TopPageに遷移
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TopPage(),
        settings: RouteSettings(name: 'TopPage'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DataViewModel>(context);

    // データが準備できていない場合、ローディングインジケーターを表示
    if (viewModel.downloadProgressMap[widget.deckID] == null ||
        viewModel.deckData[widget.deckID.toString()] == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // 左上の戻るボタンを非表示
          title: Text("ダウンロード進行中"),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 左上の戻るボタンを非表示

        title: Text("ダウンロード進行中"),
      ),
      body: Center(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/humor_dl_${widget.deckID}.png', // 画像のパス
              fit: BoxFit.contain, // 画像のフィット方法（例: contain, cover）
            ),
            Text(
              '${viewModel.deckData[widget.deckID.toString()]?['deckName'] ?? 'デッキ名不明'}の\n単語帳データを20枚だけ先に\nダウンロードしています',
              style: TextStyle(
                  fontFamily: 'ZenMaruGothic',
                  fontWeight: FontWeight.w700, // Bold
                  fontSize: 20,
                  color: Color(0xFF333333)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: LinearProgressIndicator(
                value: viewModel.downloadProgressMap[widget.deckID],
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color.fromARGB(255, 60, 177, 180),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "${(viewModel.downloadProgressMap[widget.deckID]! * 100).toInt()}%",
              style: TextStyle(
                  fontFamily: 'ZenMaruGothic',
                  fontWeight: FontWeight.w700, // Bold
                  fontSize: 20,
                  color: Color(0xFF333333)),
            ),
          ],
        ),
      ),
    );
  }
}
