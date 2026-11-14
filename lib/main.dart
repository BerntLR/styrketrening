import 'package:flutter/material.dart';

import 'intro/intro_gate.dart';
import 'l10n/app_strings.dart';
import 'pages/exercise_list_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StyrketreningApp());
}

ThemeData _buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
    ),
  );
}

class StyrketreningApp extends StatelessWidget {
  const StyrketreningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppStrings.of(context).appName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const IntroGate(child: ExerciseListPage()),
    );
  }
}
