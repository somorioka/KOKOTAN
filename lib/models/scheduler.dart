import 'collection.dart';

class Scheduler {
  Collection collection;
  int queueLimit = 50;
  int reportLimit = 1000;
  int reps = 0;
  DateTime dayCutoff = DateTime.now();

  Scheduler(this.collection);

  // Scheduler methods like getCard, answerCard, etc.
}