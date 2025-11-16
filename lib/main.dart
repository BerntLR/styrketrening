import 'package:flutter/material.dart';

import 'pages/exercise_list_page.dart';

void main() {
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
