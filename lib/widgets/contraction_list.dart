import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/contraction.dart';
import '../providers/contraction_provider.dart';

class ContractionList extends StatelessWidget {
  const ContractionList({super.key});

  String _formatTime(DateTime dt) => DateFormat('HH:mm:ss').format(dt);

  String _formatDate(DateTime dt) => DateFormat('EEEE, d MMMM y', 'pt_BR').format(dt);

  String _formatDuration(Duration d) {
    final s = d.inSeconds.remainder(60);
    if (d.inMinutes == 0) return '${s}s';
    if (s == 0) return '${d.inMinutes}min';
    return '${d.inMinutes}min ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContractionProvider>();
    final grouped = provider.groupedByDay;
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    if (days.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Nenhuma contração registrada.\nPressione o botão para iniciar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      itemBuilder: (context, i) {
        final day = days[i];
        final items = grouped[day]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                _formatDate(day),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ...List.generate(items.length, (j) {
              final c = items[j];
              final widgets = <Widget>[
                _ContractionTile(
                  contraction: c,
                  formatTime: _formatTime,
                  formatDuration: _formatDuration,
                  onDelete: () => provider.delete(c.id!),
                ),
              ];

              if (j < items.length - 1) {
                final older = items[j + 1];
                if (older.endTime != null) {
                  final gap = c.startTime.difference(older.endTime!);
                  if (gap > Duration.zero) {
                    widgets.add(_IntervalBadge(interval: gap, formatDuration: _formatDuration));
                  }
                }
              }

              return Column(mainAxisSize: MainAxisSize.min, children: widgets);
            }),
          ],
        );
      },
    );
  }
}

class _IntervalBadge extends StatelessWidget {
  final Duration interval;
  final String Function(Duration) formatDuration;

  const _IntervalBadge({required this.interval, required this.formatDuration});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_downward, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  '${formatDuration(interval)} de intervalo',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_downward, size: 12, color: Colors.grey.shade500),
              ],
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
        ],
      ),
    );
  }
}

class _ContractionTile extends StatelessWidget {
  final Contraction contraction;
  final String Function(DateTime) formatTime;
  final String Function(Duration) formatDuration;
  final VoidCallback onDelete;

  const _ContractionTile({
    required this.contraction,
    required this.formatTime,
    required this.formatDuration,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = contraction.isActive;
    final duration = contraction.duration;

    return Dismissible(
      key: ValueKey(contraction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Excluir contração?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Excluir', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? Theme.of(context).colorScheme.error.withAlpha(30)
              : Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            isActive ? Icons.timer : Icons.check,
            color: isActive
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          isActive
              ? 'Em andamento — ${formatTime(contraction.startTime)}'
              : '${formatTime(contraction.startTime)} → ${formatTime(contraction.endTime!)}',
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: isActive
            ? null
            : Text(
                'Duração: ${formatDuration(duration!)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
        trailing: isActive
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ATIVA',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            : null,
      ),
    );
  }
}
