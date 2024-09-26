import 'package:kokotan/algorithm/srs.dart';
import 'package:test/test.dart';

//成功
//srs.dartの「_」を一時的に削除して行なった。

void main() {
  group('_fillNew tests', () {
    late Scheduler scheduler;
    late Collection collection;
    late Deck testDeck;

    setUp(() {
      // コレクションとデッキのセットアップ
      collection = Collection();
      testDeck = Deck('Test Deck');

      // 20枚のダミーカードを用意
      for (var i = 0; i < 20; i++) {
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
        card.type = 0;  // 新規カードとして設定
        testDeck.addCard(card);
      }

      // デッキをコレクションに追加
      collection.addDeck(testDeck.name);
      collection.decks[testDeck.name] = testDeck;

      // スケジューラのインスタンス作成
      scheduler = Scheduler(collection);
    });

    test('新規キューが空のとき、カードが追加されるか', () {
      // 今日の新規カード消化数が0の状態で呼び出す
      scheduler.todayNewCardsCount = 0;
      
      // fillNewメソッドを実行
      final result = scheduler.fillNew();

      // 20枚のカードがキューに追加されることを期待
      expect(scheduler.newQueueCount, equals(20));
      expect(result, equals(true));  // 正常に新規カードが追加されたか確認
    });

    test('新規キューがすでに埋まっている場合、カードが追加されない', () {
      // 既に1枚カードがある状態
      scheduler.newQueue = [Card(Word(
        id: 1,
        word: 'test',
        mainMeaning: 'テスト',
        sentence: 'This is a test sentence.',
        sentenceJp: 'これはテスト文です。',
        wordVoice: '/path/to/wordVoice.mp3',
        sentenceVoice: '/path/to/sentenceVoice.mp3',
      ))];

      // fillNewメソッドを実行
      final result = scheduler.fillNew();

      // カードが既にあるので追加されないことを期待
      expect(scheduler.newQueueCount, equals(1));  // 既存の1枚のみ
      expect(result, equals(true));  // 新しいカードは追加されないが true が返る
    });

    test('今日の新規カード消化数が20枚未満のとき、新しいカードが追加される', () {
      // 今日の新規カード消化数が15枚の状態で呼び出す
      scheduler.todayNewCardsCount = 15;
      
      // fillNewメソッドを実行
      final result = scheduler.fillNew();

      // 残りの枠（5枚）がキューに追加される
      expect(scheduler.newQueueCount, equals(5));
      expect(result, equals(true));  // 正常に新規カードが追加されたか確認
    });

    test('今日の新規カード消化数が20枚以上の場合、カードが追加されない', () {
      // 今日の新規カード消化数が20枚以上の状態で呼び出す
      scheduler.todayNewCardsCount = 20;
      
      // fillNewメソッドを実行
      final result = scheduler.fillNew();

      // 新規キューが空のままで、新しいカードが追加されない
      expect(scheduler.newQueueCount, equals(0));
      expect(result, equals(false));  // 新しいカードは追加されない
    });
  });
}
