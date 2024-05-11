import 'note.dart';

class Card {
  int id;
  Note note;
  DateTime creationTime;
  int type = 0;  // 0=new, 1=learning, 2=review, 3=relearning
  int queue = 0;  // -1=suspended, 0=new, 1=learning/relearning, 2=review
  int interval = 0;  // Negative = seconds, positive = days
  double factor = 0.0;
  int reps = 0;
  int lapses = 0;
  int left = 0;
  DateTime due;

  Card(this.note) : id = uniqueId(), creationTime = DateTime.now(), due = DateTime.now();

  static int uniqueId() => DateTime.now().millisecondsSinceEpoch;
}