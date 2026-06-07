import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/contraction.dart';
import '../providers/contraction_provider.dart';
import '../utils/format_utils.dart';

class ContractionList extends StatelessWidget {
  const ContractionList({super.key});

  String _formatTime(DateTime dt) => DateFormat('HH:mm').format(dt);
  String _formatDate(DateTime dt) => DateFormat('EEEE, d MMMM y', 'pt_BR').format(dt);

  Future<void> _showEditDialog(
    BuildContext context,
    Contraction c,
    ContractionProvider provider,
  ) async {
    final result = await showDialog<Contraction>(
      context: context,
      builder: (_) => _EditDialog(contraction: c),
    );
    if (result != null) await provider.updateContraction(result);
  }

  Future<bool?> _confirmDelete(BuildContext context, Contraction c) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir contração?'),
        content: Text('Início: ${DateFormat('HH:mm').format(c.startTime)}'),
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
            style: TextStyle(color: Colors.grey, fontSize: 17),
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
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ...List.generate(items.length, (j) {
              final c = items[j];
              final widgets = <Widget>[
                Dismissible(
                  key: ValueKey(c.id),
                  direction: c.isActive
                      ? DismissDirection.none
                      : DismissDirection.horizontal,
                  background: const _SwipeBackground(isEdit: true),
                  secondaryBackground: const _SwipeBackground(isEdit: false),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      await _showEditDialog(context, c, provider);
                      return false;
                    }
                    return _confirmDelete(context, c);
                  },
                  onDismissed: (_) => provider.delete(c.id!),
                  child: _ContractionTile(
                    contraction: c,
                    formatTime: _formatTime,
                  ),
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

// ─── Swipe backgrounds ───────────────────────────────────────────────────────

class _SwipeBackground extends StatelessWidget {
  final bool isEdit;
  const _SwipeBackground({required this.isEdit});

  @override
  Widget build(BuildContext context) {
    final color = isEdit ? Colors.blue.shade400 : Colors.red.shade400;
    final label = isEdit ? 'Editar' : 'Excluir';
    final icon = isEdit ? Icons.edit_outlined : Icons.delete_outlined;

    return Container(
      color: color,
      alignment: isEdit ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isEdit
            ? [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ]
            : [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 22),
              ],
      ),
    );
  }
}

// ─── Interval badge ──────────────────────────────────────────────────────────

class _IntervalBadge extends StatelessWidget {
  final Duration interval;
  const _IntervalBadge({required this.interval});

  List<InlineSpan> _spans(TextStyle base) {
    final bold = base.copyWith(fontWeight: FontWeight.bold);
    final h = interval.inHours;
    final m = interval.inMinutes.remainder(60);
    final s = interval.inSeconds.remainder(60);
    final spans = <InlineSpan>[];
    if (h > 0) {
      spans.addAll([
        TextSpan(text: '$h', style: bold),
        TextSpan(text: 'h ', style: base),
      ]);
    }
    if (m > 0) {
      spans.addAll([
        TextSpan(text: '$m', style: bold),
        TextSpan(text: 'min ', style: base),
      ]);
    }
    if (s > 0 || spans.isEmpty) {
      spans.addAll([
        TextSpan(text: '$s', style: bold),
        TextSpan(text: 's', style: base),
      ]);
    }
    spans.add(TextSpan(text: ' de intervalo', style: base));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontSize: 14, color: Colors.grey.shade600);
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
                Icon(Icons.arrow_downward, size: 13, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                RichText(text: TextSpan(children: _spans(base))),
                const SizedBox(width: 4),
                Icon(Icons.arrow_downward, size: 13, color: Colors.grey.shade500),
              ],
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300, height: 1)),
        ],
      ),
    );
  }
}

// ─── Contraction tile ─────────────────────────────────────────────────────────

class _ContractionTile extends StatelessWidget {
  final Contraction contraction;
  final String Function(DateTime) formatTime;

  const _ContractionTile({
    required this.contraction,
    required this.formatTime,
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
            : formatTime(contraction.startTime),
        style: const TextStyle(fontSize: 15),
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
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}

class _ContractionSubtitle extends StatelessWidget {
  final Contraction contraction;
  final Duration duration;

  const _ContractionSubtitle(
      {required this.contraction, required this.duration});

  @override
  Widget build(BuildContext context) {
    final pain = contraction.painLevel;
    return Row(
      children: [
        Text(
          'Duração: ${formatDuration(duration)}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
        ),
        if (pain != null) ...[
          const SizedBox(width: 8),
          Icon(pain.icon, color: pain.color, size: 14),
          const SizedBox(width: 3),
          Text(
            pain.label,
            style: TextStyle(
              color: pain.color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Edit dialog ──────────────────────────────────────────────────────────────

class _EditDialog extends StatefulWidget {
  final Contraction contraction;
  const _EditDialog({required this.contraction});

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _secCtrl;
  PainLevel? _selectedPain;

  @override
  void initState() {
    super.initState();
    final d = widget.contraction.duration ?? Duration.zero;
    _minCtrl = TextEditingController(text: d.inMinutes.toString());
    _secCtrl =
        TextEditingController(text: d.inSeconds.remainder(60).toString());
    _selectedPain = widget.contraction.painLevel;
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
    Navigator.pop(
      context,
      Contraction(
        id: widget.contraction.id,
        startTime: widget.contraction.startTime,
        endTime: widget.contraction.startTime.add(d),
        painLevel: _selectedPain,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('HH:mm');

    return AlertDialog(
      title: const Text('Editar contração'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Início: ${fmt.format(widget.contraction.startTime)}',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text('Duração',
                style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
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
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(':',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: TextField(
                    controller: _secCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Segundos',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedOpacity(
              opacity: _currentDuration > Duration.zero ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                'Novo fim: ${fmt.format(widget.contraction.startTime.add(_currentDuration))}',
                style:
                    TextStyle(fontSize: 12, color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 20),
            Text('Nível de dor',
                style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            _PainSelector(
              selected: _selectedPain,
              onChanged: (p) => setState(() => _selectedPain = p),
            ),
          ],
        ),
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

// ─── Pain selector ────────────────────────────────────────────────────────────

class _PainSelector extends StatelessWidget {
  final PainLevel? selected;
  final void Function(PainLevel?) onChanged;

  const _PainSelector({required this.selected, required this.onChanged});

  String _shortLabel(PainLevel level) => switch (level) {
        PainLevel.none => 'Sem dor',
        PainLevel.mild => 'Leve',
        PainLevel.moderate => 'Moderada',
        PainLevel.strong => 'Forte',
      };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _PainChip(
          icon: Icons.remove_circle_outline_rounded,
          label: 'Nenhum',
          color: Colors.grey,
          selected: selected == null,
          onTap: () => onChanged(null),
        ),
        ...PainLevel.values.map(
          (level) => _PainChip(
            icon: level.icon,
            label: _shortLabel(level),
            color: level.color,
            selected: selected == level,
            onTap: () => onChanged(level),
          ),
        ),
      ],
    );
  }
}

class _PainChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PainChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(30) : Colors.transparent,
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? color : Colors.grey.shade700,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
