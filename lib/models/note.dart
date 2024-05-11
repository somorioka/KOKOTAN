class Note {
  int id;
  List<String> tags = [];

  Note() : id = uniqueId();

  void addTag(String tag) {
    if (!tags.contains(tag)) {
      tags.add(tag);
    }
  }
  static int uniqueId() {
    return DateTime.now().millisecondsSinceEpoch;  // 現在の時刻をミリ秒単位で取得
  }
}