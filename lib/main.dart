import 'package:flutter/material.dart';
import 'package:darck_puls/features/auth/welcome_page.dart';
import 'package:darck_puls/core/routes.dart'; // Import de ton fichier de routes

void main() {
  runApp(const DockPulseApp());
}

class DockPulseApp extends StatelessWidget {
  const DockPulseApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DockPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        fontFamily: 'Segoe UI',
      ),
      // On garde WelcomePage en page d'accueil initiale
      home: const WelcomePage(),
      // On enregistre les routes centralisées pour y accéder facilement
      routes: AppRoutes.define(),
    );
  }
}
