import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/contraction.dart';
import '../database/database_helper.dart';

class ContractionProvider extends ChangeNotifier {
  List<Contraction> _contractions = [];
  Contraction? _activeContraction;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  List<Contraction> get contractions => _contractions;
  Contraction? get activeContraction => _activeContraction;
  Duration get elapsed => _elapsed;
  bool get isActive => _activeContraction != null;

  Map<DateTime, List<Contraction>> get groupedByDay {
    final map = <DateTime, List<Contraction>>{};
    for (final c in _contractions) {
      final day = DateTime(c.startTime.year, c.startTime.month, c.startTime.day);
      map.putIfAbsent(day, () => []).add(c);
    }
    return map;
  }

  Future<void> load() async {
    _contractions = await DatabaseHelper.instance.getAll();
    // recover an active contraction that was never closed (app killed mid-contraction)
    final open = _contractions.where((c) => c.isActive).toList();
    if (open.isNotEmpty) {
      _activeContraction = open.first;
      _startTicker();
    }
    notifyListeners();
  }

  Future<void> toggleContraction() async {
    if (_activeContraction == null) {
      await _startContraction();
    } else {
      await _endContraction();
    }
  }

  Future<void> _startContraction() async {
    final c = Contraction(startTime: DateTime.now());
    _activeContraction = await DatabaseHelper.instance.insert(c);
    _contractions.insert(0, _activeContraction!);
    _elapsed = Duration.zero;
    _startTicker();
    notifyListeners();
  }

  Future<void> _endContraction() async {
    _ticker?.cancel();
    final closed = _activeContraction!.copyWith(endTime: DateTime.now());
    await DatabaseHelper.instance.update(closed);
    final idx = _contractions.indexWhere((c) => c.id == closed.id);
    if (idx != -1) _contractions[idx] = closed;
    _activeContraction = null;
    _elapsed = Duration.zero;
    notifyListeners();
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

  Future<void> updateContraction(Contraction updated) async {
    await DatabaseHelper.instance.update(updated);
    final idx = _contractions.indexWhere((c) => c.id == updated.id);
    if (idx != -1) _contractions[idx] = updated;
    notifyListeners();
  }

  Future<void> delete(int id) async {
    await DatabaseHelper.instance.delete(id);
    _contractions.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
