import 'dart:math';
import 'package:test/test.dart';
import 'package:clock/clock.dart';
import 'package:kokotan/algorithm/srs.dart'; 

//実行したところ、ivlが大きくなるのは、すでに前回のivlがめちゃくちゃでかいか、
//めっちゃ長い期間放置した時くらいかなあ


void main() {
  group('_nextRevIvl テスト', () {
    late Word word;
    late Scheduler scheduler;
    late Collection collection;

    setUp(() {
      word = Word(
        id: intId(),
        word: 'example',
        mainMeaning: '例',
        sentence: 'This is an example sentence.',
        sentenceJp: 'これは例文です。',
        wordVoice: 'wordVoice.mp3',
        sentenceVoice: 'sentenceVoice.mp3',
      );
      collection = Collection();
      scheduler = collection.sched;
    });

    test('次の復習間隔テスト: 30通りのケース', () {
      List<Map<String, dynamic>> testCases = [
        {'ivl': 1, 'delay': 0, 'factor': 1300, 'ease': 2},
        {'ivl': 1, 'delay': 1, 'factor': 1500, 'ease': 3},
        {'ivl': 1, 'delay': 2, 'factor': 2000, 'ease': 4},
        {'ivl': 10, 'delay': 5, 'factor': 2500, 'ease': 2},
        {'ivl': 10, 'delay': 0, 'factor': 3000, 'ease': 3},
        {'ivl': 30, 'delay': 0, 'factor': 3500, 'ease': 4},
        {'ivl': 30, 'delay': 10, 'factor': 4000, 'ease': 2},
        {'ivl': 50, 'delay': 5, 'factor': 4500, 'ease': 3},
        {'ivl': 100, 'delay': 1, 'factor': 5000, 'ease': 4},
        {'ivl': 1, 'delay': 100, 'factor': 1300, 'ease': 2},
        {'ivl': 1, 'delay': 10, 'factor': 1500, 'ease': 3},
        {'ivl': 2, 'delay': 2, 'factor': 2000, 'ease': 4},
        {'ivl': 5, 'delay': 15, 'factor': 2500, 'ease': 2},
        {'ivl': 10, 'delay': 30, 'factor': 3000, 'ease': 3},
        {'ivl': 15, 'delay': 50, 'factor': 3500, 'ease': 4},
        {'ivl': 20, 'delay': 100, 'factor': 1300, 'ease': 2},
        {'ivl': 25, 'delay': 200, 'factor': 1500, 'ease': 3},
        {'ivl': 50, 'delay': 0, 'factor': 2000, 'ease': 4},
        {'ivl': 100, 'delay': 50, 'factor': 2500, 'ease': 2},
        {'ivl': 200, 'delay': 100, 'factor': 3000, 'ease': 3},
        {'ivl': 365, 'delay': 200, 'factor': 3500, 'ease': 4},
        {'ivl': 500, 'delay': 365, 'factor': 1300, 'ease': 2},
        {'ivl': 700, 'delay': 500, 'factor': 1500, 'ease': 3},
        {'ivl': 1000, 'delay': 700, 'factor': 2000, 'ease': 4},
        {'ivl': 1500, 'delay': 1000, 'factor': 2500, 'ease': 2},
        {'ivl': 2000, 'delay': 1500, 'factor': 3000, 'ease': 3},
        {'ivl': 2500, 'delay': 2000, 'factor': 3500, 'ease': 4},
        {'ivl': 3000, 'delay': 2500, 'factor': 1300, 'ease': 2},
        {'ivl': 4000, 'delay': 3000, 'factor': 1500, 'ease': 3},
        {'ivl': 5000, 'delay': 4000, 'factor': 2000, 'ease': 4},
      ];

      for (var testCase in testCases) {
        final card = Card(word);
        card.ivl = testCase['ivl'] as int; // 必要に応じてキャスト
        card.due = clock.now().millisecondsSinceEpoch -
            ((testCase['delay'] as int) *
                24 *
                60 *
                60 *
                1000); // 遅延日数も int にキャスト
        card.factor = testCase['factor'] as int; // factor も int にキャスト

        int nextIvl =
            scheduler.nextRevIvl(card, testCase['ease'] as int); // easeもキャスト
        print(
            'IVL: ${testCase['ivl']}, Delay: ${testCase['delay']}, Factor: ${testCase['factor']}, Ease: ${testCase['ease']}, Next IVL: $nextIvl');

        expect(
          nextIvl,
          inInclusiveRange(1, 50000), // 非常に大きいivlを想定している
          reason: 'IVL should be within a reasonable range',
        );
      }
    });
  });
}
