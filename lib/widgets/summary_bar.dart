import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/contraction.dart';
import '../models/day_stats.dart';
import '../providers/contraction_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/format_utils.dart';

class SummaryBar extends StatelessWidget {
  const SummaryBar({super.key});

  static String _buildSummaryText({
    required List<Contraction> recent,
    required int count,
    required Duration? avgInterval,
    required Duration? avgDuration,
  }) {
    final now = DateTime.now();
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

    final buf = StringBuffer();
    buf.writeln('Contrações — resumo da última hora');
    buf.writeln('Gerado em ${fmt.format(now)}');
    buf.writeln();
    buf.writeln('Total: $count ${count == 1 ? 'contração' : 'contrações'}');
    buf.writeln('Intervalo médio: ${avgInterval != null ? formatDuration(avgInterval) : '—'}');
    buf.writeln('Duração média: ${avgDuration != null ? formatDuration(avgDuration) : '—'}');
    buf.writeln();
    buf.writeln('Detalhes:');
    for (int i = 0; i < recent.length; i++) {
      final c = recent[i];
      final dur = c.duration != null ? formatDuration(c.duration!) : 'em andamento';
      final pain = c.painLevel != null ? ' — ${c.painLevel!.label}' : '';
      buf.writeln('${i + 1}. ${fmt.format(c.startTime)} — $dur$pain');
    }
    return buf.toString().trimRight();
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
    final stats = DayStats(recent);
    final avgInterval = stats.averageInterval;
    final avgDuration = stats.averageDuration;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Contrações',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: hasData
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  Consumer<ThemeProvider>(
                    builder: (_, tp, _) => IconButton(
                      iconSize: 20,
                      tooltip: tp.isDark ? 'Tema claro' : 'Tema escuro',
                      icon: Icon(
                        tp.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                      ),
                      color: hasData
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                      onPressed: tp.toggle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (hasData)
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        icon: Icons.favorite_rounded,
                        value: '$count',
                        label: '${count == 1 ? 'contração' : 'contrações'}\nna última hora',
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
                        value: avgInterval != null ? formatDuration(avgInterval) : '—',
                        label: 'intervalo\nmédio',
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Copiar resumo',
                      icon: Icon(
                        Icons.share_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () {
                        final text = _buildSummaryText(
                          recent: recent,
                          count: count,
                          avgInterval: avgInterval,
                          avgDuration: avgDuration,
                        );
                        SharePlus.instance.share(ShareParams(text: text));
                      },
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Text(
                      'Nenhuma contração na última hora',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onPrimaryContainer.withAlpha(180)),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
