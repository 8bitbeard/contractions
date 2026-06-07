import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contraction_provider.dart';
import 'pain_level_sheet.dart';

class ContractionButton extends StatelessWidget {
  final VoidCallback? onContractionCompleted;

  const ContractionButton({super.key, this.onContractionCompleted});

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _onTap(BuildContext context, ContractionProvider provider) async {
    if (provider.isActive) {
      final closed = await provider.stopContraction();
      if (context.mounted) {
        await showPainLevelSheet(context, closed, provider);
      }
      // Só verifica o alerta depois que o fluxo completo terminou
      if (context.mounted) {
        onContractionCompleted?.call();
      }
    } else {
      await provider.startContraction();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ContractionProvider>();
    final isActive = provider.isActive;
    final elapsed = provider.elapsed;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _onTap(context, provider),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              boxShadow: [
                BoxShadow(
                  color: (isActive
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary)
                      .withAlpha(100),
                  blurRadius: isActive ? 32 : 16,
                  spreadRadius: isActive ? 8 : 2,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? Icons.stop : Icons.fiber_manual_record,
                    color: Colors.white,
                    size: 44,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isActive ? 'Parar' : 'Iniciar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedOpacity(
          opacity: isActive ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Text(
            _formatDuration(elapsed),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.error,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
