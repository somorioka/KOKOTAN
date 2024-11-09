//ここを足していけばデッキは増やせるハズ

Map<String, Map<String, dynamic>> InitialDeckData = {
  "1": {
    "deckID": "1",
    "deckName": "ベーシック",
    "fileUrl":
        "https://kokomirai.jp/wp-content/uploads/2024/11/bc_ver02-1.xlsx", //Firebaseでリンクを管理する
    'description':
        'シス単basic & ターゲット1400の基本単語帳にだけ載っている425単語。\n抜けている単語が一つでもあったら要注意の、最重要単語たち！',
    'level': '入試基礎レベル',
    'isReady': true,
    "isDownloaded": DownloadStatus.notDownloaded,
    "newPerDayLimit": 20, // 新規カード用の制限枚数
    "reviewPerDayLimit": 200, // 復習カード用の制限枚数
    "todayNewCardsCount": 0,
    "todayReviewCardsCount": 0,
  },
  "2": {
    "deckID": "2",
    "deckName": "スタンダードA",
    "fileUrl":
        "https://kokomirai.jp/wp-content/uploads/2024/11/sa_ver02-1.xlsx", //Firebaseでリンクを管理する
    'description':
        'シス単basic & ターゲット1400の基本単語帳と、\nシス単&ターゲット1900の標準単語帳の両方に登場する1504単語。\nこれで難関校に挑めるようになるぞ',
    'level': 'MARCH・地方国公立レベル',
    'isReady': true,
    "isDownloaded": DownloadStatus.notDownloaded,
    "newPerDayLimit": 20,
    "reviewPerDayLimit": 200,
    "todayNewCardsCount": 0,
    "todayReviewCardsCount": 0,
  },
  "3": {
    "deckID": "3",
    "deckName": "スタンダードB",
    "fileUrl": "https://example.com/deck3.zip",
    'description': 'この単語帳には500語の単語が含まれています。',
    'level': '早慶・旧帝大レベル',
    'isReady': false,
    "isDownloaded": DownloadStatus.notDownloaded,
    "newPerDayLimit": 20,
    "reviewPerDayLimit": 200,
    "todayNewCardsCount": 0,
    "todayReviewCardsCount": 0,
  },
  "4": {
    "deckID": "4",
    "deckName": "アドバンス",
    "fileUrl": "https://example.com/deck4.zip",
    'description': 'この単語帳には500語の単語が含まれています。',
    'level': '早慶上位・東大京大・医学部レベル',
    'isReady': false,
    "isDownloaded": DownloadStatus.notDownloaded,
    "newPerDayLimit": 20,
    "reviewPerDayLimit": 200,
    "todayNewCardsCount": 0,
    "todayReviewCardsCount": 0,
  }
};

// ダウンロード状態を表すenumを定義
enum DownloadStatus {
  notDownloaded, // ダウンロード前
  downloading, // ダウンロード中
  downloaded // ダウンロード済み
}
