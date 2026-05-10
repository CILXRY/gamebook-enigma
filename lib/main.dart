import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const GameBookApp());
}

class GameBookApp extends StatelessWidget {
  const GameBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '游戏本子',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
