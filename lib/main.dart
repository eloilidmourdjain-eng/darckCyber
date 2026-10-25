import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:darck_puls/features/auth/welcome_page.dart';
import 'package:darck_puls/core/routes.dart';

// Import du fichier généré par FlutterFire CLI
import 'package:darck_puls/firebase_options.dart';

void main() async {
  // 1. Assure la liaison avec le moteur natif avant l'initialisation des services
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialisation multiplateforme de Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("❌ Erreur critique lors de l'initialisation de Firebase : $e");
  }

  // 3. Lancement de l'application
  runApp(const DockPulseApp());
}

class DockPulseApp extends StatelessWidget {
  const DockPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Darck Puls',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070B14),
        fontFamily: 'Segoe UI',
      ),
      // Page d'accueil initiale
      home: const WelcomePage(),
      // Routes centralisées de l'application
      routes: AppRoutes.define(),
    );
  }
}