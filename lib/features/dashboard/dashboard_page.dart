import 'package:flutter/material.dart';

// Importations basées sur l'architecture de vos dossiers :
import 'package:darckcyber/features/auth/welcome_page.dart';
import 'package:darckcyber/features/auth/login_page.dart';
import 'package:darckcyber/features/credentials/credentials_page.dart';
import 'package:darckcyber/features/scan/network_scan_page.dart';
import 'package:darckcyber/features/simpleAdmin/simple_admin_page.dart';
import 'package:darckcyber/features/superAdmin/super_admin_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Thème couleur inspiré de l'application Cyber (Dark / Neon)
  final Color kBackgroundColor = const Color(0xFF0F172A);
  final Color kCardColor = const Color(0xFF1E293B);
  final Color kAccentColor = const Color(0xFF38BDF8);
  final Color kPrimaryColor = const Color(0xFF1E3A8A);
  final Color kTextMain = Colors.white;
  final Color kTextSecondary = const Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: const Icon(Icons.security, size: 16, color: Colors.green),
            ),
            const SizedBox(width: 10),
            // Correction du débordement (Overflow) avec Expanded & TextOverflow
            const Expanded(
              child: Text(
                "DARCK_CYBER - HUB CENTRAL",
                style: TextStyle(
                  color: Color(0xFF38BDF8),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.8,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.orange, size: 22),
            onPressed: () {
              _showCustomSnackBar(context, "Aucune alerte critique réseau en cours.", Colors.orange);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                _showProfileDialog(context);
              },
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF38BDF8),
                child: Text("EM", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête de bienvenue
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryColor.withValues(alpha: 0.6), kCardColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kAccentColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("SYSTÈME OPÉRATIONNEL ACTIF", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 6),
                    const Text("Bienvenue, Éloilid Mourdjain", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Licence Pro Programmation & Réseaux — Console Sécurisée", style: TextStyle(color: kTextSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text("NAVIGATION PRINCIPALE DES MODULES", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 12),

              // Grille de navigation vers toutes les fonctionnalités de l'architecture
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: [
                  // 1. Module Simple Admin (simple_admin_page.dart)
                  _buildNavCard(
                    context,
                    title: "Simple Admin",
                    subtitle: "Gestion & Contrôle 2FA",
                    icon: Icons.admin_panel_settings,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SimpleAdminPage()),
                      );
                    },
                  ),

                  // 2. Module Super Admin (super_admin_page.dart)
                  _buildNavCard(
                    context,
                    title: "Super Admin",
                    subtitle: "Privilèges & Daemons Root",
                    icon: Icons.security,
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SuperAdminPage()),
                      );
                    },
                  ),

                  // 3. Scanner Réseau (network_scan_page.dart)
                  _buildNavCard(
                    context,
                    title: "Scan Réseau",
                    subtitle: "Analyse ports & Kali Tools",
                    icon: Icons.radar,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NetworkScanPage()),
                      );
                    },
                  ),

                  // 4. Gestion des Identifiants (credentials_page.dart)
                  _buildNavCard(
                    context,
                    title: "Coffre Identifiants",
                    subtitle: "Mots de passe & Secrets",
                    icon: Icons.vpn_key,
                    color: kAccentColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CredentialsPage()),
                      );
                    },
                  ),

                  // 5. Authentification & Sécurité (login_page.dart)
                  _buildNavCard(
                    context,
                    title: "Authentification",
                    subtitle: "Portail SSO & Token JWT",
                    icon: Icons.lock_open,
                    color: Colors.purpleAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                  ),

                  // 6. Accueil / Welcome (welcome_page.dart)
                  _buildNavCard(
                    context,
                    title: "Écran d'Accueil",
                    subtitle: "Présentation & Intro App",
                    icon: Icons.home_filled,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WelcomePage()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section État du Système & Docker / N8n
              const Text("SERVICES & CONTENEURS ACTIFS", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    _buildServiceStatusRow("Instance Docker Locale (N8n)", "En ligne", Colors.green),
                    const Divider(color: Colors.white12, height: 20),
                    _buildServiceStatusRow("Passerelle SSH / localhost.run", "Connecté", kAccentColor),
                    const Divider(color: Colors.white12, height: 20),
                    _buildServiceStatusRow("API Anthropic Claude Connect", "Synchronisé", Colors.purple),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.3), size: 14),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceStatusRow(String serviceName, String status, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(serviceName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: statusColor.withValues(alpha: 0.4)),
          ),
          child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _showCustomSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: color.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Profil Opérateur", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nom : Éloilid Mourdjain", style: TextStyle(color: Colors.white, fontSize: 13)),
            SizedBox(height: 6),
            Text("Statut : Étudiant Licence Pro Programmation & Réseaux", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            SizedBox(height: 6),
            Text("Contacts : +261 38 75 128 40", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Fermer", style: TextStyle(color: Color(0xFF38BDF8))),
          ),
        ],
      ),
    );
  }
}