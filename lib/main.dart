import 'package:flutter/material.dart';
import 'theme/theme.dart';
import 'screens/screen.dart';

// RUSSIAN VOCABULARY APPLICATION ENTRY POINT
void main() => runApp(const RussianVocabApp());

// ROOT APPLICATION WIDGET
class RussianVocabApp extends StatelessWidget {
  const RussianVocabApp({super.key});

  @override
  Widget build(BuildContext context) {
    // CONFIGURE GLOBAL THEME AND HOME SCREEN
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const StudyScreen(),
    );
  }
}
