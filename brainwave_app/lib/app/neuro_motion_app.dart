import 'package:flutter/material.dart';

import 'auth_gate.dart';

class CerebroSyncApp extends StatelessWidget {
  const CerebroSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CerebroSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff21d4fd),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xff080914),
        fontFamily: 'Arial',
      ),
      home: const AuthGate(),
    );
  }
}
