import 'package:flutter/material.dart';
import 'package:bullpeak_intro/bullpeak_intro.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
      supportedLocales: const [Locale('en'), Locale('nb')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Follow the device language: Norwegian (nb/nn/no) or English.
      localeListResolutionCallback: (locales, supported) {
        for (final l in locales ?? const <Locale>[]) {
          if (AppStrings.isNorwegian(l)) return const Locale('nb');
          if (l.languageCode == 'en') return const Locale('en');
        }
        return const Locale('en');
      },
      themeMode: ThemeMode.system,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: const BullPeakIntro(next: ExerciseListPage()),
    );
  }
}
