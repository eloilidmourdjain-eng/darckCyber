import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// =====================================================================
// ⚠️ IMPORTS GÉRÉS SELON TON ARBORESCENCE (Vus sur tes captures)
// =====================================================================
import 'package:darck_puls/features/auth/login_page.dart'; // Pour la déconnexion

// Importation de toutes tes fenêtres métiers
import 'package:darck_puls/features/scan/network_scan_page.dart';
import 'package:darck_puls/features/network_analysis/wifi_analyzer_screen.dart';
import 'package:darck_puls/features/security/security_alerts_screen.dart';
import 'package:darck_puls/features/topology/ai_topology_screen.dart';
import 'package:darck_puls/features/traffic_management/traffic_management_screen.dart';
import 'package:darck_puls/features/provisioning/architecture_provisioning_screen.dart';
import 'package:darck_puls/features/maintenance/maintenance_screen.dart';
import 'package:darck_puls/features/superAdmin/super_admin_page.dart';

// (Optionnel) Si tu as un écran d'accueil spécifique, tu peux l'importer ici.
// Pour l'instant, on utilise une page générique pour l'accueil.
// import 'package:darck_puls/features/dashboard/home_summary_page.dart';

// --- DÉFINITION DES RÔLES (Sécurité RBAC) ---
enum UserRole { simpleAdmin, superAdmin }

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
      _buildHomeSummary(), // L'écran d'accueil (Tu pourras le remplacer par ton propre widget)
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
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo ou blason de l'application
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5))
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
                  splashColor: itemColor.withOpacity(0.2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? itemColor.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? itemColor.withOpacity(0.5) : Colors.transparent),
                      boxShadow: isSelected ? [BoxShadow(color: itemColor.withOpacity(0.1), blurRadius: 10)] : [],
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
            color: const Color(0xFF131C2D).withOpacity(0.7),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)],
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
                      color: isSelected ? itemColor.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isSelected ? itemColor.withOpacity(0.5) : Colors.transparent),
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

  // ==========================================
  // WIDGET : ÉCRAN D'ACCUEIL (Placeholder)
  // ==========================================
  // C'est l'écran affiché au lancement de l'application
  Widget _buildHomeSummary() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.checkmark_shield, color: Colors.greenAccent.withOpacity(0.5), size: 100),
          const SizedBox(height: 24),
          const Text("DARK PULSE EN LIGNE", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
          const SizedBox(height: 8),
          Text("Tous les services opérationnels.", style: TextStyle(color: Colors.blueGrey[400], fontSize: 14)),
          const SizedBox(height: 32),
          Text("Sélectionnez un module dans le menu de navigation.", style: TextStyle(color: Colors.blueGrey[500], fontSize: 12, fontStyle: FontStyle.italic)),
        ],
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