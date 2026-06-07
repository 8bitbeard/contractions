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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _alertShown = false;
  late final TabController _tabController;
  late final ScrollController _historyScrollController;
  bool _showButton = true;
  bool _showScrollTop = false;

  // Altura do centro do botão a partir do rodapé (raio + padding inferior).
  static const double _buttonRadius = 75;
  static const double _buttonBottomPad = 6;
  static const double _buttonCenter = _buttonRadius + _buttonBottomPad; // 81px

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      final onHistorico = _tabController.index == 0;
      if (_showButton != onHistorico) setState(() => _showButton = onHistorico);
    });
    _historyScrollController = ScrollController();
    _historyScrollController.addListener(() {
      final show = _historyScrollController.offset > 80;
      if (_showScrollTop != show) setState(() => _showScrollTop = show);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _historyScrollController.dispose();
    super.dispose();
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
    final isDark = theme.brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const SummaryBar(),
            const SizedBox(height: 6),
            TabBar(
              controller: _tabController,
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
                    controller: _tabController,
                    children: [
                      SingleChildScrollView(
                        controller: _historyScrollController,
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

                  // Gradiente: transparente no topo → sólido no centro do botão.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: _buttonCenter,
                    height: 210,
                    child: AnimatedOpacity(
                      opacity: _showButton ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                      child: IgnorePointer(
                        child: DecoratedBox(
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
                  ),

                  // Área sólida + botão (do centro do botão para baixo).
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnimatedOpacity(
                      opacity: _showButton ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                      child: IgnorePointer(
                        ignoring: !_showButton,
                        child: Container(
                          color: theme.colorScheme.surface,
                          padding: const EdgeInsets.only(
                            top: 4,
                            bottom: _buttonBottomPad,
                          ),
                          child: Center(
                            child: ContractionButton(
                              onContractionCompleted: _checkLaborAlert,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Botão de scroll ao topo (só no histórico, fora do topo).
                  Positioned(
                    right: 16,
                    bottom: _buttonCenter + 210 + 12,
                    child: AnimatedOpacity(
                      opacity: (_showScrollTop && _showButton) ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 220),
                      child: IgnorePointer(
                        ignoring: !(_showScrollTop && _showButton),
                        child: FloatingActionButton.small(
                          heroTag: 'scrollTop',
                          tooltip: 'Voltar ao topo',
                          onPressed: () => _historyScrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          ),
                          child: const Icon(Icons.keyboard_arrow_up_rounded),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
