import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/contraction.dart';
import '../providers/contraction_provider.dart';

class ContractionList extends StatelessWidget {
  const ContractionList({super.key});

  String _formatTime(DateTime dt) => DateFormat('HH:mm:ss').format(dt);

  String _formatDate(DateTime dt) => DateFormat('EEEE, d MMMM y', 'pt_BR').format(dt);

  static String formatDuration(Duration d) {
    final s = d.inSeconds.remainder(60);
    if (d.inMinutes == 0) return '${s}s';
    if (s == 0) return '${d.inMinutes}min';
    return '${d.inMinutes}min ${s}s';
  }

  Future<void> _showEditDialog(BuildContext context, Contraction c, ContractionProvider provider) async {
    final newDuration = await showDialog<Duration>(
      context: context,
      builder: (_) => _EditDurationDialog(contraction: c),
    );
    if (newDuration != null) {
      final updated = c.copyWith(endTime: c.startTime.add(newDuration));
      await provider.updateContraction(updated);
    }
  }

  Future<void> _confirmDelete(BuildContext context, Contraction c, ContractionProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir contração?'),
        content: Text(
          'Início: ${DateFormat('HH:mm:ss').format(c.startTime)}'
          '${c.endTime != null ? '\nFim: ${DateFormat('HH:mm:ss').format(c.endTime!)}' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) await provider.delete(c.id!);
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
                  onEdit: c.isActive ? null : () => _showEditDialog(context, c, provider),
                  onDelete: () => _confirmDelete(context, c, provider),
                ),
              ];

              if (j < items.length - 1) {
                final older = items[j + 1];
                if (older.endTime != null) {
                  final gap = c.startTime.difference(older.endTime!);
                  if (gap > Duration.zero) {
                    widgets.add(_IntervalBadge(interval: gap));
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

  const _IntervalBadge({required this.interval});

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
                  '${ContractionList.formatDuration(interval)} de intervalo',
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
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  const _ContractionTile({
    required this.contraction,
    required this.formatTime,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = contraction.isActive;
    final duration = contraction.duration;
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isActive
            ? theme.colorScheme.error.withAlpha(30)
            : theme.colorScheme.primaryContainer,
        child: Icon(
          isActive ? Icons.timer : Icons.check,
          color: isActive ? theme.colorScheme.error : theme.colorScheme.primary,
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
          : _ContractionSubtitle(contraction: contraction, duration: duration!),
      trailing: isActive
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ATIVA',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: theme.colorScheme.primary,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Editar',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outlined, size: 18),
                  color: theme.colorScheme.error,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Excluir',
                  onPressed: onDelete,
                ),
              ],
            ),
    );
  }
}

class _ContractionSubtitle extends StatelessWidget {
  final Contraction contraction;
  final Duration duration;

  const _ContractionSubtitle({required this.contraction, required this.duration});

  static const _painIcons = {
    PainLevel.none: Icons.sentiment_very_satisfied_rounded,
    PainLevel.mild: Icons.sentiment_satisfied_rounded,
    PainLevel.moderate: Icons.sentiment_dissatisfied_rounded,
    PainLevel.strong: Icons.sentiment_very_dissatisfied_rounded,
  };

  static const _painColors = {
    PainLevel.none: Color(0xFF4CAF50),
    PainLevel.mild: Color(0xFFFFC107),
    PainLevel.moderate: Color(0xFFFF9800),
    PainLevel.strong: Color(0xFFF44336),
  };

  @override
  Widget build(BuildContext context) {
    final pain = contraction.painLevel;
    return Row(
      children: [
        Text(
          'Duração: ${ContractionList.formatDuration(duration)}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        if (pain != null) ...[
          const SizedBox(width: 8),
          Icon(_painIcons[pain]!, color: _painColors[pain]!, size: 14),
          const SizedBox(width: 3),
          Text(
            pain.label,
            style: TextStyle(
              color: _painColors[pain]!,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _EditDurationDialog extends StatefulWidget {
  final Contraction contraction;

  const _EditDurationDialog({required this.contraction});

  @override
  State<_EditDurationDialog> createState() => _EditDurationDialogState();
}

class _EditDurationDialogState extends State<_EditDurationDialog> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _secCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.contraction.duration ?? Duration.zero;
    _minCtrl = TextEditingController(text: d.inMinutes.toString());
    _secCtrl = TextEditingController(text: d.inSeconds.remainder(60).toString());
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _secCtrl.dispose();
    super.dispose();
  }

  Duration get _currentDuration {
    final m = int.tryParse(_minCtrl.text) ?? 0;
    final s = int.tryParse(_secCtrl.text) ?? 0;
    return Duration(minutes: m, seconds: s);
  }

  void _save() {
    final d = _currentDuration;
    if (d <= Duration.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A duração deve ser maior que zero.')),
      );
      return;
    }
    Navigator.pop(context, d);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm:ss');
    return AlertDialog(
      title: const Text('Editar duração'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Início: ${fmt.format(widget.contraction.startTime)}',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Minutos',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: TextField(
                  controller: _secCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Segundos',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            opacity: _currentDuration > Duration.zero ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Text(
              'Novo fim: ${fmt.format(widget.contraction.startTime.add(_currentDuration))}',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
