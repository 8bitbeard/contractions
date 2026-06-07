import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/contraction_provider.dart';
import '../widgets/contraction_button.dart';
import '../widgets/contraction_list.dart';
import '../widgets/stats_section.dart';
import '../widgets/summary_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _alertShown = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  void _checkLaborAlert() {
    if (!mounted) return;
    final provider = context.read<ContractionProvider>();
    final shouldAlert = provider.shouldShowLaborAlert;

    if (!shouldAlert) {
      _alertShown = false;
      return;
    }

    if (!_alertShown) {
      _alertShown = true;
      _showLaborAlert();
    }
  }

  void _showLaborAlert() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.favorite_rounded,
          size: 44,
          color: theme.colorScheme.primary,
        ),
        title: const Text(
          'Suas contrações estão bem frequentes! 🌸',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Percebemos que suas contrações estão ocorrendo com intervalos de '
          '10 minutos ou menos — isso é um sinal muito importante de que o '
          'trabalho de parto ativo pode estar começando.\n\n'
          'Agora é uma ótima hora para acionar seu plano de parto: avise seu '
          'acompanhante, entre em contato com seu médico ou obstetra e '
          'considere se dirigir à maternidade.\n\n'
          'Você está arrasando, mamãe! Respira fundo, mantém a calma e '
          'confia no seu corpo — você foi feita para isso. 💜',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi, vou me preparar!'),
          ),
        ],
      ),
    ).then((_) {
      // Permite exibir novamente se o alerta for dispensado e a condição persistir
      _alertShown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const SummaryBar(),
              const SizedBox(height: 6),
              TabBar(
                tabs: const [
                  Tab(icon: Icon(Icons.list_alt_outlined), text: 'Histórico'),
                  Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Estatísticas'),
                ],
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
                dividerColor: theme.colorScheme.outlineVariant,
              ),
              Expanded(
                child: Stack(
                  children: [
                    TabBarView(
                      children: [
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: const [
                              ContractionList(),
                              SizedBox(height: 24),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: const [
                              StatsSection(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Container(
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme.colorScheme.surface.withAlpha(0),
                                theme.colorScheme.surface,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 36, bottom: 24),
                child: Center(
                  child: ContractionButton(onContractionCompleted: _checkLaborAlert),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
