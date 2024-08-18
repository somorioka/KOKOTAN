import 'package:fake_async/fake_async.dart';
import 'package:kokotan/algorithm/srs.dart';
import 'package:test/test.dart';

void main() {
  test('Scheduler correctly resets and updates new card queue after a day', () {
    // 初期の時間を設定
    final initialTime = DateTime(2023, 6, 30);

    // ダミーデータを作成
    final word = Word(
      id: 1,
      word: 'test',
      mainMeaning: 'テスト',
      sentence: 'This is a test sentence.',
      sentenceJp: 'これはテストの文です。',
      wordVoice: '/path/to/wordVoice.mp3',
      sentenceVoice: '/path/to/sentenceVoice.mp3',
    );

    final card = Card(word);

    // Collection クラスのインスタンスを作成し、デッキとカードを追加
    var collection = Collection();
    var deckName = 'Test Deck';
    collection.addDeck(deckName);
    collection.addCardToDeck(deckName, card);

    // Scheduler クラスのインスタンスを作成
    final scheduler = Scheduler(collection);

    // 仮想的な時間を使ってテストを実行
    FakeAsync(initialTime: initialTime).run((fakeAsync) {
      // 初期状態でのキューを確認
      expect(scheduler.newQueueCount, equals(1)); // ダミーカードが1枚あると仮定

      // 時間を1日進める
      fakeAsync.elapse(const Duration(days: 1));

      // リセット後の新しい日付でのキューを確認
      expect(scheduler.newQueueCount, equals(1)); // ダミーカードが新規キューに追加されていることを確認

      // 更にもう1日進める
      fakeAsync.elapse(const Duration(days: 1));

      // 新たなリセットが正しく行われたか確認
      expect(scheduler.newQueueCount, equals(1)); // 再びリセットされて、新規キューが更新される
    });
  });
}
