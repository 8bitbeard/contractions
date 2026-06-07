import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/contraction_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  final prefs = await SharedPreferences.getInstance();
  final initialDark = prefs.getBool(ThemeProvider.prefKey) ?? false;
  runApp(ContractionApp(initialDark: initialDark));
}

class ContractionApp extends StatelessWidget {
  final bool initialDark;
  const ContractionApp({super.key, required this.initialDark});

  static const _seed = Color(0xFF7B3FA0);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ContractionProvider()..load()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(initialDark: initialDark)),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, _) => MaterialApp(
          title: 'Contrações',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: _seed,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: _seed,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
