import 'package:darckcyber/features/auth/login_page.dart';
import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 650),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // En-tête / Badge système
                  Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF38BDF8),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                          child: Text(
                        "DOCKPULSE // ENGIN CORE V1.8 // SYSTEM INITIALIZATION",
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                          ),
                      ),
                    ],
                  ),
                  const Divider(
                    color: Color(0xFF1F2937),
                    height: 24,
                    thickness: 1,
                  ),
                  const SizedBox(height: 10),

                  // Logo du projet
                  Center(
                    child: Image.asset(
                      'assets/logo.png',
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Texte descriptif (Corrigé : CONNECTER)
                  const Center(
                    child: Text(
                      "CONNECTER VOTRE RESEAU LOCAL AU TABLEAU DE BORD",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Bouton principal d'action
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                        ),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () {
                      // Action de navigation vers la page de connexion
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "CONTINUER VERS L'AUTHENTIFICATION",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Pied de page de la carte (Statut réseau & Paramètres)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.wifi,
                            color: Color(0xFF94A3B8),
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Network Status : WAITING",
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          // Action parametres
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.settings,
                              color: Color(0xFF94A3B8),
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "Settings",
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Lien d'initialisation (Corrigé : utilisation)
                  GestureDetector(
                    onTap: () {
                      // Action pour initialiser le jeton (Premiere utilisation)
                    },
                    child: Center(
                      child: Text(
                        "Premiere utilisation ? Initialiser le jeton",
                        style: TextStyle(
                          color: const Color(0xFF38BDF8),
                          fontSize: 11,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}