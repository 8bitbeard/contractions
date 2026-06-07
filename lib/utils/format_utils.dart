String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);

  if (h > 0) {
    if (m == 0 && s == 0) return '${h}h';
    if (s == 0) return '${h}h ${m}min';
    if (m == 0) return '${h}h ${s}s';
    return '${h}h ${m}min ${s}s';
  }
  if (m == 0) return '${s}s';
  if (s == 0) return '${m}min';
  return '${m}min ${s}s';
}
