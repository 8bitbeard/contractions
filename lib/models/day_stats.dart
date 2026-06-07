import 'contraction.dart';

class DayStats {
  final List<Contraction> all;

  DayStats(List<Contraction> contractions)
      : all = List.of(contractions)..sort((a, b) => a.startTime.compareTo(b.startTime));

  List<Contraction> get completed => all.where((c) => !c.isActive).toList();

  int get count => all.length;

  Duration? get averageDuration {
    if (completed.isEmpty) return null;
    final total = completed.fold(Duration.zero, (s, c) => s + c.duration!);
    return Duration(microseconds: total.inMicroseconds ~/ completed.length);
  }

  List<Duration> get intervals {
    final c = completed;
    final result = <Duration>[];
    for (int i = 1; i < c.length; i++) {
      final gap = c[i].startTime.difference(c[i - 1].endTime!);
      if (gap > Duration.zero) result.add(gap);
    }
    return result;
  }

  Duration? get averageInterval {
    final iv = intervals;
    if (iv.isEmpty) return null;
    final total = iv.fold(Duration.zero, (s, d) => s + d);
    return Duration(microseconds: total.inMicroseconds ~/ iv.length);
  }

  Duration? get longestDuration => completed.isEmpty
      ? null
      : completed.map((c) => c.duration!).reduce((a, b) => a > b ? a : b);

  Duration? get shortestDuration => completed.isEmpty
      ? null
      : completed.map((c) => c.duration!).reduce((a, b) => a < b ? a : b);

  Duration? get totalDuration => completed.isEmpty
      ? null
      : completed.fold<Duration>(Duration.zero, (s, c) => s + c.duration!);

  /// 24 slots de 1h cada (índice 0 = 00h–01h, ..., 23 = 23h–00h)
  List<int> get contractionsBySlot {
    final slots = List.filled(24, 0);
    for (final c in all) {
      slots[c.startTime.hour]++;
    }
    return slots;
  }
}
