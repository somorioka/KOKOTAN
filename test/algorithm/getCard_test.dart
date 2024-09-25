// test/scheduler_get_card_test.dart
import 'package:kokotan/algorithm/srs.dart'; // 適切なパスに修正してください
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Flutterのバインディングを初期化
  TestWidgetsFlutterBinding.ensureInitialized();

  group('getCard() メソッドのテスト', () {
    late Collection collection;
    late Scheduler scheduler;

    setUp(() async {
      // SharedPreferencesのモック初期値を設定
      SharedPreferences.setMockInitialValues({});

      // 現在時刻を使用する
      collection = Collection();
      scheduler = Scheduler(collection);
      await scheduler.initializeScheduler();
      collection.addDeck('Default');

      print('--- テストのセットアップ完了 ---');
    });

    test('どのキューにもカードがない場合はnullを返す', () async {
      // Act: getCard()を呼び出す
      Card? card = scheduler.getCard();
      print('取得したカード: ${card?.word.word}');

      // Assert: nullが返されることを確認
      expect(card, isNull);
    });

    test('新規カードのみが利用可能な場合は新規カードを返す', () async {
      // Arrange: 新規カードを1枚追加
      Word word = Word(
        id: 1,
        word: 'New Card',
        mainMeaning: '新規カード',
        sentence: 'これは新規カードのテストです。',
        sentenceJp: 'これは新規カードのテストです。',
        wordVoice: 'new_card.mp3',
        sentenceVoice: 'new_card_sentence.mp3',
      );
      Card newCard = Card(word);
      // 新規カードのdueを現在時刻に設定
      newCard.due = DateTime.now().millisecondsSinceEpoch;
      newCard.type = 0; // 新規カードとして初期化
      newCard.queue = 0; // 新規キュー
      collection.addCardToDeck('Default', newCard);
      print('新規カードを追加: ${newCard.word.word}');

      // Act: getCard()を呼び出す
      Card? card = scheduler.getCard();
      print('取得したカード: ${card?.word.word}, due: ${card?.due}');

      // Assert: 新規カードが返されることを確認
      expect(card, isNotNull);
      expect(card!.word.word, equals('New Card'));
      expect(card.queue, equals(0)); // 新規キュー
    });

    test('学習カードのみが利用可能な場合は学習カードを返す', () async {
      // Arrange: 学習カードを1枚追加
      Word word = Word(
        id: 2,
        word: 'Learning Card',
        mainMeaning: '学習カード',
        sentence: 'これは学習カードのテストです。',
        sentenceJp: 'これは学習カードのテストです。',
        wordVoice: 'learning_card.mp3',
        sentenceVoice: 'learning_card_sentence.mp3',
      );
      Card learningCard = Card(word);
      // 学習カードのdueを現在時刻に設定
      learningCard.due = DateTime.now().millisecondsSinceEpoch;
      learningCard.type = 1; // 学習カードとして初期化
      learningCard.queue = 1; // 学習キュー
      collection.addCardToDeck('Default', learningCard);
      print('学習カードを追加: ${learningCard.word.word}');

      // Act: getCard()を呼び出す
      Card? card = scheduler.getCard();
      print('取得したカード: ${card?.word.word}, due: ${card?.due}');

      // Assert: 学習カードが返されることを確認
      expect(card, isNotNull);
      expect(card!.word.word, equals('Learning Card'));
      expect(card.queue, equals(1)); // 学習キュー
    });

    test('復習カードのみが利用可能な場合は復習カードを返す', () async {
      // Arrange: 復習カードを1枚追加
      Word word = Word(
        id: 3,
        word: 'Review Card',
        mainMeaning: '復習カード',
        sentence: 'これは復習カードのテストです。',
        sentenceJp: 'これは復習カードのテストです。',
        wordVoice: 'review_card.mp3',
        sentenceVoice: 'review_card_sentence.mp3',
      );
      Card reviewCard = Card(word);
      // 復習カードのdueを現在時刻に設定
      reviewCard.due = DateTime.now().millisecondsSinceEpoch;
      reviewCard.type = 2; // 復習カードとして初期化
      reviewCard.queue = 2; // 復習キュー
      collection.addCardToDeck('Default', reviewCard);
      print('復習カードを追加: ${reviewCard.word.word}');

      // Act: getCard()を呼び出す
      Card? card = scheduler.getCard();
      print('取得したカード: ${card?.word.word}, due: ${card?.due}');

      // Assert: 復習カードが返されることを確認
      expect(card, isNotNull);
      expect(card!.word.word, equals('Review Card'));
      expect(card.queue, equals(2)); // 復習キュー
    });

    test('学習カードは新規カードおよび復習カードより優先される', () async {
      // Arrange: 新規カード、学習カード、復習カードを各1枚追加

      // 新規カード
      Word newWord = Word(
        id: 4,
        word: 'New Card',
        mainMeaning: '新規カード',
        sentence: 'これは新規カードのテストです。',
        sentenceJp: 'これは新規カードのテストです。',
        wordVoice: 'new_card.mp3',
        sentenceVoice: 'new_card_sentence.mp3',
      );
      Card newCard = Card(newWord);
      newCard.due = DateTime.now().millisecondsSinceEpoch;
      newCard.type = 0; // 新規カード
      newCard.queue = 0; // 新規キュー
      collection.addCardToDeck('Default', newCard);

      // 学習カード
      Word learningWord = Word(
        id: 5,
        word: 'Learning Card',
        mainMeaning: '学習カード',
        sentence: 'これは学習カードのテストです。',
        sentenceJp: 'これは学習カードのテストです。',
        wordVoice: 'learning_card.mp3',
        sentenceVoice: 'learning_card_sentence.mp3',
      );
      Card learningCard = Card(learningWord);
      learningCard.due = DateTime.now().millisecondsSinceEpoch; // 現在時刻に設定
      learningCard.type = 1; // 学習カード
      learningCard.queue = 1; // 学習キュー
      collection.addCardToDeck('Default', learningCard);

      // 復習カード
      Word reviewWord = Word(
        id: 6,
        word: 'Review Card',
        mainMeaning: '復習カード',
        sentence: 'これは復習カードのテストです。',
        sentenceJp: 'これは復習カードのテストです。',
        wordVoice: 'review_card.mp3',
        sentenceVoice: 'review_card_sentence.mp3',
      );
      Card reviewCard = Card(reviewWord);
      reviewCard.due = DateTime.now().millisecondsSinceEpoch; // 現在時刻に設定
      reviewCard.type = 2; // 復習カード
      reviewCard.queue = 2; // 復習キュー
      collection.addCardToDeck('Default', reviewCard);

     
      // Act: getCard() を呼び出す
      Card? nextCard = scheduler.getCard();
      print('次に取得したカード: ${nextCard?.word.word}, due: ${nextCard?.due}');

      // Assert: Learning Card が再度取得されることを確認
      expect(nextCard, isNotNull);
      expect(nextCard!.word.word, equals('Learning Card'));
      expect(nextCard.queue, equals(1)); // 学習キュー
    });
  });
}
