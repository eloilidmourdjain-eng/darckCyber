import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:darck_puls/features/auth/login_page.dart'; // Pour la déconnexion

// Importation de toutes tes fenêtres métiers
import 'package:darck_puls/core/models/user_role.dart';
import 'package:darck_puls/features/scan/network_scan_page.dart';
import 'package:darck_puls/features/network_analysis/wifi_analyzer_screen.dart';
import 'package:darck_puls/features/security/security_alerts_screen.dart';
import 'package:darck_puls/features/topology/ai_topology_screen.dart';
import 'package:darck_puls/features/traffic_management/traffic_management_screen.dart';
import 'package:darck_puls/features/provisioning/architecture_provisioning_screen.dart';
import 'package:darck_puls/features/maintenance/maintenance_screen.dart';
import 'package:darck_puls/features/superAdmin/super_admin_page.dart';

class MainNavigationScreen extends StatefulWidget {
  final UserRole role; // Habilitation injectée lors du Login

  const MainNavigationScreen({super.key, required this.role});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late List<Widget> _screens;
  late List<NavigationItem> _navItems;

  @override
  void initState() {
    super.initState();
    _initializeMenu();
  }

  // --- MOTEUR DE GÉNÉRATION DYNAMIQUE DU MENU (RBAC) ---
  void _initializeMenu() {
    // 1. Liste des fenêtres communes (Pour tous les administrateurs)
    _screens = [
      const HomeSummaryView(), // 🚀 L'ÉCRAN D'ACCUEIL ANIMÉ
      const NetworkScanPage(),
      const WifiAnalyzerScreen(),
      const SecurityAlertsScreen(),
      const AITopologyScreen(),
      const TrafficManagementScreen(),
      const ArchitectureAndProvisioningScreen(),
      const MaintenanceScreen(),
    ];

    _navItems = [
      NavigationItem(icon: CupertinoIcons.home, label: "Accueil"),
      NavigationItem(icon: CupertinoIcons.search, label: "Scanner"),
      NavigationItem(icon: CupertinoIcons.waveform_path, label: "Wi-Fi"),
      NavigationItem(icon: CupertinoIcons.shield_lefthalf_fill, label: "Sécurité"),
      NavigationItem(icon: CupertinoIcons.map_pin_ellipse, label: "AIOps"),
      NavigationItem(icon: CupertinoIcons.slider_horizontal_3, label: "Trafic"),
      NavigationItem(icon: CupertinoIcons.square_stack_3d_up, label: "Infra (IaC)"),
      NavigationItem(icon: CupertinoIcons.wrench_fill, label: "NetOps"),
    ];

    // 2. PRIVILÈGE SUPER ADMIN : Ajout de la Console Restreinte
    if (widget.role == UserRole.superAdmin) {
      _screens.add(const SuperAdminToolsPage()); // La War Room
      _navItems.add(NavigationItem(
          icon: CupertinoIcons.flame_fill, // Icône plus agressive pour le Root
          label: "Root Console",
          color: const Color(0xFFFF2A55) // Rouge Néon
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint Responsive : Desktop/Tablette vs Mobile
        bool isDesktop = constraints.maxWidth > 900;

        return Scaffold(
          backgroundColor: const Color(0xFF070B14), // Noir très profond
          body: Row(
            children: [
              // --- MENU LATÉRAL (Pour PC/Linux/Mac) ---
              if (isDesktop)
                _buildDesktopSidebar(),

              // --- CONTENU PRINCIPAL ---
              Expanded(
                child: Stack(
                  children: [
                    // Moteur d'affichage avec transition fluide
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutExpo,
                      switchOutCurve: Curves.easeInExpo,
                      child: _screens[_currentIndex],
                    ),

                    // --- BARRE DE NAVIGATION FLOTTANTE (Pour Mobile iOS/Android) ---
                    if (!isDesktop)
                      Positioned(
                        bottom: 20, left: 16, right: 16,
                        child: _buildMobileBottomBar(),
                      )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // WIDGET : BARRE LATÉRALE (DESKTOP)
  // ==========================================
  Widget _buildDesktopSidebar() {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF131C2D), // Fond carte
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20)],
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo ou blason de l'application
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5))
            ),
            child: const Icon(CupertinoIcons.waveform_path_ecg, color: Color(0xFF00E5FF), size: 30),
          ),
          const SizedBox(height: 30),

          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                bool isSelected = _currentIndex == index;
                Color itemColor = _navItems[index].color ?? const Color(0xFF00E5FF);

                return InkWell(
                  onTap: () => setState(() => _currentIndex = index),
                  splashColor: itemColor.withValues(alpha: 0.2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? itemColor.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? itemColor.withValues(alpha: 0.5) : Colors.transparent),
                      boxShadow: isSelected ? [BoxShadow(color: itemColor.withValues(alpha: 0.1), blurRadius: 10)] : [],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _navItems[index].icon,
                          color: isSelected ? itemColor : Colors.blueGrey[400],
                          size: 24,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _navItems[index].label,
                          style: TextStyle(
                              color: isSelected ? Colors.white : Colors.blueGrey[400],
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bouton de déconnexion (Zero Trust)
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: IconButton(
              icon: const Icon(CupertinoIcons.power, color: Colors.redAccent),
              tooltip: "Verrouiller la session",
              onPressed: () {
                // Détruit le routeur actuel et retourne au login
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET : BARRE DE NAVIGATION (MOBILE)
  // ==========================================
  Widget _buildMobileBottomBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 85,
          decoration: BoxDecoration(
            color: const Color(0xFF131C2D).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
          ),
          // Scroll Horizontal (Très utile car l'app a de nombreuses fenêtres)
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: List.generate(_navItems.length, (index) {
                bool isSelected = _currentIndex == index;
                Color itemColor = _navItems[index].color ?? const Color(0xFF00E5FF);

                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? itemColor.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isSelected ? itemColor.withValues(alpha: 0.5) : Colors.transparent),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            _navItems[index].icon,
                            color: isSelected ? itemColor : Colors.blueGrey[400],
                            size: 22
                        ),
                        const SizedBox(height: 4),
                        Text(
                            _navItems[index].label,
                            style: TextStyle(
                                color: isSelected ? Colors.white : Colors.blueGrey[400],
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                            )
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// MODÈLE DE DONNÉES
// ==========================================
class NavigationItem {
  final IconData icon;
  final String label;
  final Color? color;

  NavigationItem({required this.icon, required this.label, this.color});
}

// =====================================================================
// NOUVEL ÉCRAN D'ACCUEIL : HOME SUMMARY (Animé, Logo Custom, Cyber)
// =====================================================================
class HomeSummaryView extends StatefulWidget {
  const HomeSummaryView({super.key});

  @override
  State<HomeSummaryView> createState() => _HomeSummaryViewState();
}

class _HomeSummaryViewState extends State<HomeSummaryView> with TickerProviderStateMixin {
  late AnimationController _bgLogoController;
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Animation pour la lévitation (sans rotation)
    _bgLogoController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

    // Animation d'entrée des cartes (Fade-In et Glissement)
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutExpo));

    _entryController.forward();
  }

  @override
  void dispose() {
    _bgLogoController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // --- 1. ARRIÈRE-PLAN : TON LOGO ANIMÉ (Lévitation uniquement) ---
        Positioned.fill(
          child: AnimatedBuilder(
              animation: _bgLogoController,
              builder: (context, child) {
                // Lévitation douce (Mouvement haut/bas lent)
                final dy = math.sin(_bgLogoController.value * 2 * math.pi) * 30;

                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Opacity(
                    opacity: 0.04, // Effet filigrane (Watermark)
                    child: Center(
                      child: Image.asset(
                        'logo.png', // 👈 CORRECTION: Chemin mis à jour vers la racine !
                        width: 600,
                        height: 600,
                        fit: BoxFit.contain,
                        // Fallback de sécurité robuste au cas où l'image n'est pas dans le pubspec
                        errorBuilder: (context, error, stackTrace) => const Icon(
                            CupertinoIcons.shield_lefthalf_fill,
                            size: 600,
                            color: Colors.white
                        ),
                      ),
                    ),
                  ),
                );
              }
          ),
        ),

        // Filtre de verre dépoli par-dessus le logo pour l'incruster dans l'UI
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),

        // --- 2. CONTENU PRINCIPAL (Cartes et Stats) ---
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: Colors.greenAccent)),
                          child: const Icon(CupertinoIcons.checkmark_shield_fill, color: Colors.greenAccent, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("DARK PULSE CORE", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            Text("Tous les systèmes sont opérationnels.", style: TextStyle(color: Colors.blueGrey[400], fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Grid des statistiques rapides (NOC)
                    const Text("VUE D'ENSEMBLE (NOC)", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = constraints.maxWidth > 600 ? 3 : 1;
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: constraints.maxWidth > 600 ? 2.0 : 3.0,
                            children: [
                              _buildStatCard("Uptime Réseau", "99.98%", CupertinoIcons.timer, const Color(0xFF00E5FF)),
                              _buildStatCard("Menaces Isolées", "1,204", CupertinoIcons.shield_lefthalf_fill, const Color(0xFFFF2A55)),
                              _buildStatCard("Nœuds Actifs", "42", CupertinoIcons.device_desktop, const Color(0xFF8B5CF6)),
                            ],
                          );
                        }
                    ),

                    const SizedBox(height: 48),

                    // Activités récentes simulées
                    const Text("ACTIVITÉ RÉCENTE", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 16),
                    _buildActivityRow("Synchronisation GitOps (Vault) réussie.", "Il y a 5 min", CupertinoIcons.cloud_upload),
                    _buildActivityRow("Analyse Wi-Fi de routine terminée.", "Il y a 12 min", CupertinoIcons.waveform_path),
                    _buildActivityRow("Nouvel accès Administrateur (John_Doe).", "Il y a 45 min", CupertinoIcons.person_alt),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGET UTILITAIRE : Carte Statistique ---
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131C2D).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text(title, style: TextStyle(color: Colors.blueGrey[400], fontSize: 11)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET UTILITAIRE : Ligne d'activité ---
  Widget _buildActivityRow(String text, String time, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131C2D).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey[300], size: 18),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          Text(time, style: TextStyle(color: Colors.blueGrey[500], fontSize: 10)),
        ],
      ),
    );
  }
}