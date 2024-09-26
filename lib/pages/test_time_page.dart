// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:kokotan/view_models/data_view_model.dart';

// class TestTimePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Test Scheduler Page'),
//       ),
//       body: Consumer<DataViewModel>(
//         builder: (context, viewModel, child) {
//           return Column(
//             children: [
//               // カードの状態を表示する部分
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     _buildCardStatus(
//                       label: '未学習',
//                       count: viewModel.newCardCount,
//                     ),
//                     _buildCardStatus(
//                       label: '覚え中',
//                       count: viewModel.learningCardCount,
//                     ),
//                     _buildCardStatus(
//                       label: '復習中',
//                       count: viewModel.reviewCardCount,
//                     ),
//                   ],
//                 ),
//               ),

//               // カードの内容表示
//               Expanded(
//                 child: Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       if (viewModel.currentWord != null) ...[
//                         Text(
//                           viewModel.currentWord!.word,
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         SizedBox(height: 16),
//                         Text(
//                           viewModel.currentWord!.mainMeaning,
//                           style: TextStyle(fontSize: 18),
//                         ),
//                       ] else ...[
//                         Text(
//                           'カードがありません',
//                           style: TextStyle(fontSize: 18),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ),
//               ),

//               // ボタンでカードを仕分けする部分
//               if (viewModel.currentWord != null) ...[
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       _buildAnswerButton(context, viewModel, '覚え直す', 1),
//                       _buildAnswerButton(context, viewModel, '微妙', 2),
//                       _buildAnswerButton(context, viewModel, 'OK', 3),
//                       _buildAnswerButton(context, viewModel, '余裕', 4),
//                     ],
//                   ),
//                 ),
//               ],

//               // 時計を進めるボタン
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     _buildTimeControlButton(
//                       context,
//                       viewModel,
//                       '1分進める',
//                       () => viewModel.advanceTestTimeBy(24 * 60 * 60 * 1000),
//                     ),
//                     _buildTimeControlButton(
//                       context,
//                       viewModel,
//                       '10分進める',
//                       () => viewModel.advanceTestTimeBy(10 * 60 * 1000),
//                     ),
//                     _buildTimeControlButton(
//                       context,
//                       viewModel,
//                       '1日進める',
//                       () => viewModel.advanceTestTimeBy(1 * 60 * 1000),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   // カードの状態を表示するウィジェット
//   Widget _buildCardStatus({required String label, required int count}) {
//     return Column(
//       children: [
//         Text(label,
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//         SizedBox(height: 8),
//         Text('$count 枚', style: TextStyle(fontSize: 18)),
//       ],
//     );
//   }

//   // カード仕分け用のボタン
//   Widget _buildAnswerButton(
//       BuildContext context, DataViewModel viewModel, String label, int ease) {
//     return ElevatedButton(
//       onPressed: () async {
//         await viewModel.answerCard(ease, context);
//       },
//       child: Text(label),
//     );
//   }

//   // 時間を進めるボタンのウィジェット
//   Widget _buildTimeControlButton(BuildContext context, DataViewModel viewModel,
//       String label, VoidCallback onPressed) {
//     return ElevatedButton(
//       onPressed: onPressed,
//       child: Text(label),
//     );
//   }
// }
