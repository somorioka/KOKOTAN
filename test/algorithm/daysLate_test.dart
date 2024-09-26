import 'dart:math';
import 'package:test/test.dart';
import 'package:clock/clock.dart';
import 'package:kokotan/algorithm/srs.dart'; 

void main() {
  group('daysLate テスト', () {
    // インスタンス化の共通処理
    late Word word;
    late Scheduler scheduler;
    late Collection collection;

    setUp(() {
      // テストごとに新しいインスタンスを生成
      word = Word(
        id: intId(),
        word: 'example',
        mainMeaning: '例',
        sentence: 'This is an example sentence.',
        sentenceJp: 'これは例文です。',
        wordVoice: 'wordVoice.mp3',
        sentenceVoice: 'sentenceVoice.mp3',
      );

      collection = Collection(); // Collectionのインスタンスを生成
      scheduler = collection.sched; // Schedulerを生成
    });

    test('通常のケース: 現在の時間が due を超えている', () {
      final card = Card(word); // 適切なカードのセットアップ
      card.due = clock.now().millisecondsSinceEpoch -
          2 * 86400 * 1000; // 2日前の due（ミリ秒）

      final result = scheduler.daysLate(card);
      expect(result, 2 * 24 * 60 * 60 * 1000); // 2日遅れをミリ秒で期待
    });

    test('遅延がないケース: 現在の時間が due と同じ', () {
      final card = Card(word);
      card.due = clock.now().millisecondsSinceEpoch; // ちょうど今の due（ミリ秒）

      final result = scheduler.daysLate(card);
      expect(result, 0); // 遅延がないので 0
    });

    test('未来のカード: 現在の時間が due より前', () {
      final card = Card(word);
      card.due = clock.now().millisecondsSinceEpoch +
          2 * 86400 * 1000; // 2日後の due（ミリ秒）

      final result = scheduler.daysLate(card);
      expect(result, 0); // 未来の due なので遅延なし
    });

    test('境界条件テスト: due がちょうど1日前', () {
      final card = Card(word);
      card.due =
          clock.now().millisecondsSinceEpoch - 86400 * 1000; // 1日前の due（ミリ秒）

      final result = scheduler.daysLate(card);
      expect(result, 24 * 60 * 60 * 1000); // 1日遅れをミリ秒で期待
    });

    test('異常な due の値: 非常に未来の due', () {
      final card = Card(word);
      card.due =
          clock.now().millisecondsSinceEpoch + 1000000000 * 1000; // 非常に未来（ミリ秒）

      final result = scheduler.daysLate(card);
      expect(result, 0); // 遅延なし
    });

    test('異常な due の値: 負の due', () {
      final card = Card(word);
      card.due = -1; // 異常な負の値

      final result = scheduler.daysLate(card);
      expect(result, clock.now().millisecondsSinceEpoch + 1); // 負の due の場合の遅延
    });
  });
}
