import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contraction_provider.dart';

class SummaryBar extends StatelessWidget {
  const SummaryBar({super.key});

  static String _fmt(Duration d) {
    final s = d.inSeconds.remainder(60);
    if (d.inMinutes == 0) return '${s}s';
    if (s == 0) return '${d.inMinutes}min';
    return '${d.inMinutes}min ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContractionProvider>();
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));

    final recent = provider.contractions
        .where((c) => c.startTime.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final count = recent.length;

    final completed = recent.where((c) => !c.isActive).toList();
    Duration? avgInterval;
    if (completed.length >= 2) {
      final gaps = <Duration>[];
      for (int i = 1; i < completed.length; i++) {
        final gap = completed[i].startTime.difference(completed[i - 1].endTime!);
        if (gap > Duration.zero) gaps.add(gap);
      }
      if (gaps.isNotEmpty) {
        final total = gaps.fold<Duration>(Duration.zero, (s, d) => s + d);
        avgInterval = Duration(microseconds: total.inMicroseconds ~/ gaps.length);
      }
    }

    final theme = Theme.of(context);
    final hasData = count > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        color: hasData
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: hasData
              ? Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        icon: Icons.favorite_rounded,
                        value: '$count',
                        label: 'contração${count == 1 ? '' : 'ões'}\nna última hora',
                      ),
                    ),
                    VerticalDivider(
                      width: 32,
                      thickness: 1,
                      color: theme.colorScheme.primary.withAlpha(60),
                    ),
                    Expanded(
                      child: _Metric(
                        icon: Icons.swap_horiz_rounded,
                        value: avgInterval != null ? _fmt(avgInterval) : '—',
                        label: 'intervalo\nmédio',
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Text(
                      'Nenhuma contração na última hora',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Metric({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onPrimaryContainer.withAlpha(180)),
            ),
          ],
        ),
      ],
    );
  }
}
