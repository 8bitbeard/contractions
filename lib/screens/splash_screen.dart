import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/contraction_provider.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  bool _navigationScheduled = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_navigationScheduled) {
      _navigationScheduled = true;
      _scheduleNavigation();
    }
  }

  void _scheduleNavigation() {
    final provider = context.read<ContractionProvider>();
    final minDelay = Future.delayed(const Duration(milliseconds: 1800));

    Future<void> waitForLoad() async {
      if (provider.isLoaded) return;
      final completer = Completer<void>();
      void listener() {
        if (provider.isLoaded) {
          provider.removeListener(listener);
          completer.complete();
        }
      }
      provider.addListener(listener);
      return completer.future;
    }

    Future.wait([minDelay, waitForLoad()]).then((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, _, _) => const HomeScreen(),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final iconSize = screenSize.longestSide * 1.15;

    return Scaffold(
      backgroundColor: const Color(0xFF7B3FA0),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ícone grande e semi-transparente como fundo
            Positioned(
              child: Image.asset(
                'assets/icon/icon.png',
                width: iconSize,
                height: iconSize,
                opacity: const AlwaysStoppedAnimation(0.12),
                fit: BoxFit.contain,
              ),
            ),
            // Nome do aplicativo centralizado
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Contrações',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withAlpha(60),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Registro de contrações uterinas',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withAlpha(180),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
