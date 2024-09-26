import 'package:test/test.dart';
import 'package:kokotan/algorithm/srs.dart';
import 'package:clock/clock.dart';
import 'dart:math';

//fillRevが正常に動くかテストし、成功
//srs.dartの「_」を一時的に削除して行なった。
//シャッフルの確認はコードをうまく書けなかったので、ログで確認。いけてた。

void main() {
  group('_fillRev tests', () {
    late Scheduler scheduler;
    late Collection collection;
    late Deck testDeck;

    setUp(() {
      // コレクションとデッキのセットアップ
      collection = Collection();
      testDeck = Deck('Test Deck');

      // 5枚のダミーカードを用意（queue == 2で復習用）
      for (var i = 0; i < 5; i++) {
        final word = Word(
          id: i + 1,
          word: 'test$i',
          mainMeaning: 'テスト$i',
          sentence: 'This is a test sentence $i.',
          sentenceJp: 'これはテスト文です $i。',
          wordVoice: '/path/to/wordVoice.mp3',
          sentenceVoice: '/path/to/sentenceVoice.mp3',
        );
        final card = Card(word);
        card.queue = 2; // 復習カードとして設定
        card.due = clock.now().millisecondsSinceEpoch + i * 1000; // `due` を設定
        testDeck.addCard(card);
      }

      // デッキをコレクションに追加
      collection.addDeck(testDeck.name);
      collection.decks[testDeck.name] = testDeck;

      // スケジューラのインスタンス作成
      scheduler = Scheduler(collection);
    });

    test('復習キューが空でない場合、何もしない', () {
      // 既に復習キューに1枚追加
      scheduler.revQueue.add(Card(Word(
        id: 1,
        word: 'test',
        mainMeaning: 'テスト',
        sentence: 'This is a test sentence.',
        sentenceJp: 'これはテスト文です。',
        wordVoice: '/path/to/wordVoice.mp3',
        sentenceVoice: '/path/to/sentenceVoice.mp3',
      )));

      // fillRevを実行
      final result = scheduler.fillRev();

      // 追加のカードはないはず
      expect(scheduler.revQueue.length, equals(1));
      expect(result, equals(true));
    });

    test('復習キューが空のとき、カードを追加するか', () {
      // 復習キューは最初は空のはず
      expect(scheduler.revQueue.isEmpty, equals(true));

      // fillRevメソッドを実行
      final result = scheduler.fillRev();

      // 5枚のカードが復習キューに追加されることを期待
      expect(scheduler.revQueue.length, equals(5));
      expect(result, equals(true));
    });

    test('limitが適用され、復習カード数が制限されるか', () {
      // queueLimitを4に設定（最大4枚まで復習）
      scheduler.queueLimit = 4;

      // fillRevメソッドを実行
      scheduler.fillRev();

      // 4枚に制限されていることを確認
      expect(scheduler.revQueue.length, equals(4));
    });

    test('期限以内のカードのみを復習キューに追加するか', () {
      // 今日の日付を取得
      final now = DateTime.now().millisecondsSinceEpoch;

      // 期限が今日のカードを作成
      final dueTodayCard = Card(Word(
        id: 1,
        word: 'test_due_today',
        mainMeaning: 'テスト',
        sentence: 'Test sentence',
        sentenceJp: 'テスト文',
        wordVoice: '/path/to/wordVoice.mp3',
        sentenceVoice: '/path/to/sentenceVoice.mp3',
      ));
      dueTodayCard.due = now; // 今日の期限を設定
      dueTodayCard.queue = 2; // 復習カードとして設定

      // 期限が未来のカードを作成
      final dueFutureCard = Card(Word(
        id: 2,
        word: 'test_due_future',
        mainMeaning: 'テスト',
        sentence: 'Test sentence',
        sentenceJp: 'テスト文',
        wordVoice: '/path/to/wordVoice.mp3',
        sentenceVoice: '/path/to/sentenceVoice.mp3',
      ));
      dueFutureCard.due = now + Duration(days: 1).inMilliseconds; // 明日以降の期限
      dueFutureCard.queue = 2; // 復習カードとして設定

      // カードをデッキに追加
      testDeck.addCard(dueTodayCard);
      testDeck.addCard(dueFutureCard);

      // スケジューラのインスタンス作成
      scheduler = Scheduler(collection);

      // fillRevメソッドを実行して、期限内のカードがキューに追加されるか確認
      final result = scheduler.fillRev();

      // 復習キューに期限内のカードが追加されているかを確認
      expect(scheduler.revQueue.contains(dueTodayCard), equals(true));
      expect(scheduler.revQueue.contains(dueFutureCard),
          equals(false)); // 未来のカードは含まれない
      expect(result, equals(true)); // 成功を確認
    });
  });
}
