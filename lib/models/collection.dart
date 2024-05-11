import 'package:kokotan/models/scheduler.dart';

import 'card.dart';
import 'note.dart';

class Collection {
  DateTime creationTime = DateTime.now();
  List<Card> cards = [];
  Scheduler? scheduler;

  Collection() {
    scheduler = Scheduler(this);
  }

  void addNote(Note note) {
    cards.add(Card(note));
  }
}