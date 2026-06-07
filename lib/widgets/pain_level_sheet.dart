import 'package:flutter/material.dart';
import '../models/contraction.dart';
import '../providers/contraction_provider.dart';

Future<void> showPainLevelSheet(
  BuildContext context,
  Contraction contraction,
  ContractionProvider provider,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PainLevelSheet(
      contraction: contraction,
      provider: provider,
    ),
  );
}

class _PainLevelSheet extends StatelessWidget {
  final Contraction contraction;
  final ContractionProvider provider;

  const _PainLevelSheet({required this.contraction, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Como foi essa contração?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Selecione o nível de dor (opcional)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          ...PainLevel.values.map((level) => _PainOption(
                level: level,
                onTap: () async {
                  final updated = contraction.copyWith(painLevel: level);
                  await provider.updateContraction(updated);
                  if (context.mounted) Navigator.pop(context);
                },
              )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Pular'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PainOption extends StatelessWidget {
  final PainLevel level;
  final VoidCallback onTap;

  const _PainOption({required this.level, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: level.color.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: level.color.withAlpha(60), width: 1.5),
          ),
          child: Row(
            children: [
              Icon(level.icon, color: level.color, size: 28),
              const SizedBox(width: 14),
              Text(
                level.label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
