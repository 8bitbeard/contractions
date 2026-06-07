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

  // Geometria do botão (deve refletir o tamanho definido em ContractionButton).
  static const double _buttonSize = 150;
  static const double _buttonTopPad = 4;
  static const double _buttonBottomPad = 6;
  // Distâncias a partir do rodapé da tela:
  static const double _buttonCenterFromBottom =
      _buttonBottomPad + _buttonSize / 2; // 81 px
  static const double _buttonTopFromBottom =
      _buttonBottomPad + _buttonSize; // 156 px
  static const double _buttonContainerH =
      _buttonTopPad + _buttonSize + _buttonBottomPad; // 160 px
  // Zona de fade acima do botão.
  static const double _fadeZoneH = 200;
  static const double _overlayH = _fadeZoneH + _buttonContainerH; // 360 px

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

                  // Overlay unificado: gradiente com paradas precisas + botão.
                  //
                  // Paradas calculadas de cima para baixo no total de _overlayH:
                  //   stop 0.0  → topo da zona de fade    → alpha 0   (transparente)
                  //   stopTop   → topo do botão            → alpha 64  (~25% opaco)
                  //   stopCenter→ centro do botão          → alpha 255 (sólido)
                  //   stop 1.0  → base da tela             → alpha 255 (sólido)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: _overlayH,
                    child: AnimatedOpacity(
                      opacity: _showButton ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOut,
                      child: Stack(
                        children: [
                          // Gradiente (não recebe toques).
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    stops: [
                                      0.0,
                                      (_overlayH - _buttonTopFromBottom) / _overlayH,
                                      (_overlayH - _buttonCenterFromBottom) / _overlayH,
                                      1.0,
                                    ],
                                    colors: [
                                      theme.colorScheme.surface.withAlpha(0),
                                      theme.colorScheme.surface.withAlpha(191),
                                      theme.colorScheme.surface,
                                      theme.colorScheme.surface,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Botão posicionado na base do overlay.
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: IgnorePointer(
                              ignoring: !_showButton,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: _buttonTopPad,
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
                        ],
                      ),
                    ),
                  ),

                  // Botão de scroll ao topo (só no histórico, fora do topo).
                  Positioned(
                    right: 16,
                    bottom: _overlayH - 60,
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
