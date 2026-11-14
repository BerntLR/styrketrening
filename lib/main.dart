import 'package:flutter/material.dart';

import 'l10n/app_strings.dart';

import 'intro/intro_gate.dart';
import 'pages/exercise_list_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StyrketreningApp());
}

class StyrketreningApp extends StatelessWidget {
  const StyrketreningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) {
        final strings = AppStrings.of(context);
        return strings.appName;
      },
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ).surface,
        appBarTheme: AppBarTheme(
          backgroundColor: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ).surface,
          foregroundColor: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ).onSurface,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ).surface,
        appBarTheme: AppBarTheme(
          backgroundColor: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ).surface,
          foregroundColor: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ).onSurface,
        ),
      ),
      home: IntroGate(child: const ExerciseListPage()),
    );
  }
}
