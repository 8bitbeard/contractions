import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/contraction.dart';
import '../database/database_helper.dart';

class ContractionProvider extends ChangeNotifier with WidgetsBindingObserver {
  List<Contraction> _contractions = [];
  Contraction? _activeContraction;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  bool _isLoaded = false;

  Map<DateTime, List<Contraction>>? _groupedByDayCache;

  List<Contraction> get contractions => _contractions;
  Contraction? get activeContraction => _activeContraction;
  Duration get elapsed => _elapsed;
  bool get isActive => _activeContraction != null;
  bool get isLoaded => _isLoaded;

  Map<DateTime, List<Contraction>> get groupedByDay {
    return _groupedByDayCache ??= _buildGroupedByDay();
  }

  Map<DateTime, List<Contraction>> _buildGroupedByDay() {
    final map = <DateTime, List<Contraction>>{};
    for (final c in _contractions) {
      final day = DateTime(c.startTime.year, c.startTime.month, c.startTime.day);
      map.putIfAbsent(day, () => []).add(c);
    }
    return map;
  }

  void _invalidateCache() => _groupedByDayCache = null;

  Future<void> load() async {
    WidgetsBinding.instance.addObserver(this);
    _contractions = await DatabaseHelper.instance.getAll();
    _invalidateCache();
    final open = _contractions.where((c) => c.isActive).toList();
    if (open.isNotEmpty) {
      _activeContraction = open.first;
      _startTicker();
    }
    _isLoaded = true;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _activeContraction != null) {
      _elapsed = DateTime.now().difference(_activeContraction!.startTime);
      notifyListeners();
    }
  }

  Future<void> toggleContraction() async {
    if (_activeContraction == null) {
      await startContraction();
    } else {
      await stopContraction();
    }
  }

  Future<void> startContraction() async {
    final c = Contraction(startTime: DateTime.now());
    _activeContraction = await DatabaseHelper.instance.insert(c);
    _contractions.insert(0, _activeContraction!);
    _invalidateCache();
    _elapsed = Duration.zero;
    _startTicker();
    notifyListeners();
  }

  Future<Contraction> stopContraction() async {
    _ticker?.cancel();
    final closed = _activeContraction!.copyWith(endTime: DateTime.now());
    await DatabaseHelper.instance.update(closed);
    final idx = _contractions.indexWhere((c) => c.id == closed.id);
    if (idx != -1) {
      _contractions[idx] = closed;
      _invalidateCache();
    }
    _activeContraction = null;
    _elapsed = Duration.zero;
    notifyListeners();
    return closed;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activeContraction != null) {
        _elapsed = DateTime.now().difference(_activeContraction!.startTime);
        notifyListeners();
      }
    });
  }

  bool get shouldShowLaborAlert {
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    final recent = _contractions
        .where((c) => c.startTime.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (recent.length < 5) return false;

    bool hasInterval = false;
    for (int i = 1; i < recent.length; i++) {
      final prev = recent[i - 1];
      if (prev.endTime == null) continue;
      hasInterval = true;
      final gap = recent[i].startTime.difference(prev.endTime!);
      if (gap > const Duration(minutes: 10)) return false;
    }

    return hasInterval;
  }

  Future<void> updateContraction(Contraction updated) async {
    await DatabaseHelper.instance.update(updated);
    final idx = _contractions.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _contractions[idx] = updated;
      _invalidateCache();
    }
    notifyListeners();
  }

  Future<void> delete(int id) async {
    await DatabaseHelper.instance.delete(id);
    _contractions.removeWhere((c) => c.id == id);
    _invalidateCache();
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }
}
