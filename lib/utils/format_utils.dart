String formatDuration(Duration d) {
  final s = d.inSeconds.remainder(60);
  if (d.inMinutes == 0) return '${s}s';
  if (s == 0) return '${d.inMinutes}min';
  return '${d.inMinutes}min ${s}s';
}
