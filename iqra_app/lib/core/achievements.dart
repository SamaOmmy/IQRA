import 'package:flutter/material.dart';

import 'store.dart';

class Milestone {
  const Milestone(this.id, this.title, this.how, this.icon, this.value, this.target);
  final String id, title, how;
  final IconData icon;
  final int value, target;
  bool get unlocked => value >= target;
  double get progress => target == 0 ? 1 : (value / target).clamp(0, 1).toDouble();
}

/// Gentle milestones computed from what the person has done. Nothing is sent anywhere.
List<Milestone> milestonesFor(AppStore s) {
  final totalPages = s.daysRead.values.fold<int>(0, (a, b) => a + b);
  final salah = s.salah;
  var fullDays = 0;
  var best = 0, run = 0;
  final keys = salah.keys.toList()..sort();
  for (final k in keys) {
    if ((salah[k]?.length ?? 0) >= 5) {
      fullDays++;
      run++;
      if (run > best) best = run;
    } else {
      run = 0;
    }
  }
  return [
    Milestone('first', 'First page', 'Read your first page', Icons.auto_stories_rounded, totalPages, 1),
    Milestone('p50', 'Fifty pages', 'Read 50 pages', Icons.menu_book_rounded, totalPages, 50),
    Milestone('p300', 'Three hundred pages', 'Read 300 pages', Icons.collections_bookmark_rounded, totalPages, 300),
    Milestone('khatam', 'Khatam', 'Complete the whole Qur’an', Icons.emoji_events_rounded, s.khatams, 1),
    Milestone('s3', 'Three days', 'Read 3 days in a row', Icons.local_fire_department_rounded, s.streak, 3),
    Milestone('s7', 'One week', 'Read 7 days in a row', Icons.local_fire_department_rounded, s.streak, 7),
    Milestone('s30', 'One month', 'Read 30 days in a row', Icons.whatshot_rounded, s.streak, 30),
    Milestone('story10', 'Story lover', 'Read 10 stories', Icons.import_contacts_rounded, s.storiesRead.length, 10),
    Milestone('story50', 'Student of the seerah', 'Read 50 stories', Icons.school_rounded, s.storiesRead.length, 50),
    Milestone('mem10', 'Memoriser', 'Mark 10 verses as memorised', Icons.psychology_rounded, s.memorised.length, 10),
    Milestone('mem100', 'Hundred verses', 'Mark 100 verses as memorised', Icons.workspace_premium_rounded, s.memorised.length, 100),
    Milestone('dhikr', 'Remembering', 'Reach 1,000 on the tasbih', Icons.touch_app_rounded, s.tasbihTotal, 1000),
    Milestone('salah1', 'All five', 'Log all five prayers in a day', Icons.check_circle_rounded, fullDays, 1),
    Milestone('salah7', 'Steady prayer', 'Log all five prayers 7 days running', Icons.mosque_rounded, best, 7),
    Milestone('quiz', 'Sharp mind', 'Score 9 or more in the quiz', Icons.quiz_rounded, s.quizBest, 9),
    Milestone('notes', 'Reflections', 'Write 5 verse notes', Icons.edit_note_rounded, s.notes.length, 5),
    Milestone('plan', 'On a plan', 'Start a khatam plan', Icons.flag_rounded, s.plan == null ? 0 : 1, 1),
  ];
}
