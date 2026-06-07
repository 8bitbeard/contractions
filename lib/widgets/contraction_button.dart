import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contraction_provider.dart';

class ContractionButton extends StatelessWidget {
  const ContractionButton({super.key});

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
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
          onTap: provider.toggleContraction,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 140,
            height: 140,
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
                    size: 36,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActive ? 'Parar' : 'Iniciar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
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
