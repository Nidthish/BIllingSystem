import 'package:flutter/material.dart';
import 'screens/home_shell.dart';

void main() {
  runApp(const BillingSystemApp());
}

class BillingSystemApp extends StatelessWidget {
  const BillingSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Billing System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Segoe UI',
        scaffoldBackgroundColor: const Color(0xFF0F1117),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF4F8EF7),
          secondary: const Color(0xFF6C63FF),
          surface: const Color(0xFF1A1D27),
        ),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}
