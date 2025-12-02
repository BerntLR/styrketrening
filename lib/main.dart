import 'package:flutter/material.dart';
import 'dart:async';

import 'pages/exercise_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Delay for splashscreen ---
  await Future.delayed(const Duration(seconds: 2));

  runApp(const StyrketreningApp());
}

class StyrketreningApp extends StatelessWidget {
  const StyrketreningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'styrketrening',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const ExerciseListPage(),
    );
  }
}
