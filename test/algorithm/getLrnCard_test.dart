import 'package:flutter_test/flutter_test.dart';
import 'package:clock/clock.dart';
import 'package:kokotan/algorithm/srs.dart';



void main() {
  group('getLrnCard Tests', () {
    late Collection collection;
    late Scheduler scheduler;
    late Clock testClock;

    setUp(() {
      // テスト用の固定された現在時刻を設定
      testClock = Clock();
      collection = Collection();
      scheduler = Scheduler(collection);

      // テスト用のカードをデッキに追加
      Word word = Word(
        id: 1,
        word: 'Learning Card',
        mainMeaning: '学習カード',
        sentence: 'This is a learning card.',
        sentenceJp: 'これは学習用のカードです。',
        wordVoice: 'learning_word_voice.mp3',
        sentenceVoice: 'learning_sentence_voice.mp3',
      );
      Card learningCard = Card(word);
      learningCard.due = testClock.now().millisecondsSinceEpoch; // 現在時刻
      learningCard.queue = 1; // 学習キューに移動
      learningCard.type = 1; // カードタイプを1に設定
      collection.addDeck('Test Deck');
      collection.addCardToDeck('Test Deck', learningCard); // デッキにカードを追加
    });

    test('collapse = false の場合、due が現在時刻以下の学習カードが取得される', () {
      // Arrange: 学習カードを追加した状態で fillLrn を実行
      scheduler.fillLrn(); // 学習キューを埋める

      // Act: 学習カードを取得
      Card? result = scheduler.getLrnCard(collapse: false);

      // Assert: 学習カードが取得されることを確認
      expect(result, isNotNull);
      expect(result!.word.word, equals('Learning Card'));
      expect(result.type, equals(1)); // カードタイプが1であることを確認
    });

    test('collapse = false の場合、due が未来の学習カードは取得されない', () {
      // Arrange: due が未来の学習カードを追加
      Word futureWord = Word(
        id: 2,
        word: 'Future Learning Card',
        mainMeaning: '未来の学習カード',
        sentence: 'This card is for future learning.',
        sentenceJp: 'これは未来の学習カードです。',
        wordVoice: 'future_learning_word_voice.mp3',
        sentenceVoice: 'future_learning_sentence_voice.mp3',
      );
      Card futureCard = Card(futureWord);
      futureCard.due =
          testClock.now().millisecondsSinceEpoch + 100000; // 未来のdue
      futureCard.queue = 1; // 学習キューに移動
      futureCard.type = 1; // カードタイプを3に設定
      collection.addCardToDeck('Test Deck', futureCard); // デッキにカードを追加

      // Act: 学習カードを取得
      scheduler.fillLrn(); // 学習キューを埋める
      Card? result = scheduler.getLrnCard(collapse: false);

      // Assert: 現在時刻のdueを持つカードが取得されることを確認
      expect(result, isNotNull);
      expect(result!.word.word, equals('Learning Card'));
      expect(result.type, equals(1)); // カードタイプが1であることを確認
    });

    test('collapse = true の場合、collapse 時間内の学習カードが取得される', () {
      // Arrange: collapse 時間内の学習カードを追加
      Word collapseWord = Word(
        id: 3,
        word: 'Collapse Learning Card',
        mainMeaning: 'Collapse 学習カード',
        sentence: 'This is a collapse learning card.',
        sentenceJp: 'これは collapse 学習カードです。',
        wordVoice: 'collapse_learning_word_voice.mp3',
        sentenceVoice: 'collapse_learning_sentence_voice.mp3',
      );
      Card collapseCard = Card(collapseWord);
      collapseCard.due =
          testClock.now().millisecondsSinceEpoch + 1000; // 少し先の時間
      collapseCard.queue = 1; // 学習キューに移動
      collapseCard.type = 1; // カードタイプを1に設定
      collection.addCardToDeck('Test Deck', collapseCard); // デッキにカードを追加

      // Act: collapse = true で学習カードを取得
      scheduler.fillLrn(); // 学習キューを埋める
      Card? result = scheduler.getLrnCard(collapse: true);

      // Assert: collapse 時間内のカードが取得されることを確認
      expect(result, isNotNull);
      expect(result!.word.word, equals('Collapse Learning Card'));
      expect(result.type, equals(1)); // カードタイプが1であることを確認
    });
  });
}
