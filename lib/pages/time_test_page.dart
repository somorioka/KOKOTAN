import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kokotan/pages/flashcard_screen.dart';
import 'package:provider/provider.dart';
import 'package:kokotan/view_models/data_view_model.dart';

class TimeTestPage extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Time Test Page'),
      ),
      body: Consumer<DataViewModel>(
        builder: (context, viewModel, child) {
          final card = viewModel.currentCard;
          final word = card?.word;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Time: ${viewModel.currentTime}'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    DateTime newTime = DateTime(
                      viewModel.currentTime.year,
                      viewModel.currentTime.month,
                      viewModel.currentTime.day + 1,
                      7,
                    );
                    viewModel.setCurrentTime(newTime); // 次の日の7時に変更
                    viewModel.triggerCheckDay();
                  },
                  child: Text('次の日の朝にする'),
                ),
                ElevatedButton(
                  onPressed: () {
                    DateTime newTime =
                        viewModel.currentTime.add(Duration(minutes: 1));
                    viewModel.setCurrentTime(newTime); // 1分後に変更
                  },
                  child: Text('１分後にする'),
                ),
                ElevatedButton(
                  onPressed: () {
                    DateTime newTime =
                        viewModel.currentTime.add(Duration(minutes: 10));
                    viewModel.setCurrentTime(newTime); // 10分後に変更
                  },
                  child: Text('10分後にする'),
                ),
                ElevatedButton(
                  onPressed: () {
                    DateTime newTime =
                        viewModel.currentTime.add(Duration(hours: 1));
                    viewModel.setCurrentTime(newTime); // 1時間後に変更
                  },
                  child: Text('１時間後にする'),
                ),
                SizedBox(height: 32),
                if (word != null) ...[
                  Text(
                    word.word,
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  // ステータスごとに色を変更
                  Text(
                    '${getCardQueueLabel(card?.queue ?? -1)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: getCardQueueColor(card?.queue ?? -1), // 色を指定
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '今日できるカードあと${viewModel.newCardCount + viewModel.learningCardCount + viewModel.reviewCardCount}枚',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '未学習のカードあと${viewModel.newCardCount}枚',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    '覚え中のカードあと${viewModel.learningCardCount}枚',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    '復習のカードあと${viewModel.reviewCardCount}枚',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      _buildCustomButton(
                        context,
                        '覚え直す',
                        Color.fromARGB(255, 255, 91, 91),
                        viewModel,
                      ),
                      _buildCustomButton(
                        context,
                        '微妙',
                        Color.fromARGB(255, 111, 243, 197),
                        viewModel,
                      ),
                      _buildCustomButton(
                        context,
                        'OK',
                        Color.fromARGB(255, 83, 209, 161),
                        viewModel,
                      ),
                      _buildCustomButton(
                        context,
                        '余裕',
                        Color.fromARGB(255, 33, 176, 175),
                        viewModel,
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'No cards available',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomButton(BuildContext context, String label, Color color,
      DataViewModel viewModel) {
    return ElevatedButton(
      onPressed: () async {
        int ease = _getEaseValue(label);
        await viewModel.answerCard(ease, context);
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // 角丸なし
        ),
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(label),
    );
  }

  int _getEaseValue(String label) {
    switch (label) {
      case '覚え直す':
        return 1;
      case '微妙':
        return 2;
      case 'OK':
        return 3;
      case '余裕':
        return 4;
      default:
        return 1;
    }
  }

  String getCardQueueLabel(int queue) {
    switch (queue) {
      case 0:
        return "未学習";
      case 1:
        return "覚え中";
      case 2:
        return "復習";
      default:
        return "Unknown";
    }
  }

  // カードのキューに応じた色を返す関数
  Color getCardQueueColor(int queue) {
    switch (queue) {
      case 0:
        return Colors.blue; // 未学習は青
      case 1:
        return Colors.red; // 覚え中は赤
      case 2:
        return Colors.green; // 復習は緑
      default:
        return Colors.black; // 不明なステータスは黒
    }
  }
}
