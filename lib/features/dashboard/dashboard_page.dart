import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:darck_puls/features/auth/login_page.dart';

import 'package:darck_puls/core/models/user_role.dart';
import 'package:darck_puls/features/scan/network_scan_page.dart';
import 'package:darck_puls/features/network_analysis/wifi_analyzer_screen.dart';
import 'package:darck_puls/features/security/security_alerts_screen.dart';
import 'package:darck_puls/features/topology/ai_topology_screen.dart';
import 'package:darck_puls/features/traffic_management/traffic_management_screen.dart';
import 'package:darck_puls/features/provisioning/architecture_provisioning_screen.dart';
import 'package:darck_puls/features/maintenance/maintenance_screen.dart';
import 'package:darck_puls/features/superAdmin/super_admin_page.dart';
import 'package:darck_puls/features/logs/log_center_screen.dart';
import 'package:darck_puls/features/settings/system_settings_screen.dart';


class MainNavigationScreen extends StatefulWidget {
  final UserRole role;

  const MainNavigationScreen({super.key, required this.role});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;

  late List<Widget> _screens;
  late List<NavigationItem> _navItems;
  late AnimationController _pulseController; // 🚀 NOUVEAU: Contrôleur pour le Logo

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _initializeMenu();
  }

  void _initializeMenu() {
    _screens = [
      const HomeSummaryView(),
      const NetworkScanPage(),
      const WifiAnalyzerScreen(),
      const SecurityAlertsScreen(),
      const AITopologyScreen(),
      const TrafficManagementScreen(),
      const ArchitectureAndProvisioningScreen(),
      const MaintenanceScreen(),
      const LogCenterScreen(),
      const SystemSettingsScreen(),
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
      NavigationItem(icon: CupertinoIcons.list_bullet_indent, label: "Logs SIEM"),
      NavigationItem(icon: CupertinoIcons.settings, label: "Réglages"),
    ];

    if (widget.role == UserRole.superAdmin) {
      _screens.add(const SuperAdminToolsPage());
      _navItems.add(NavigationItem(
          icon: CupertinoIcons.flame_fill,
          label: "Root Console",
          color: const Color(0xFFFF2A55)
      ));
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // --- PROTOCOLE DE DÉCONNEXION SÉCURISÉE (DevSecOps) ---
  void _executeSecureLogout(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        Future.delayed(const Duration(seconds: 2), () {
          if (!context.mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            CupertinoPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
          );
        });

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF070B14).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5), width: 2),
                boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.2), blurRadius: 40)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.lock_shield_fill, color: Colors.redAccent, size: 60),
                  const SizedBox(height: 24),
                  const Text("FERMETURE DE SESSION", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text("Purge des jetons cryptographiques en RAM...", style: GoogleFonts.jetBrainsMono(color: Colors.blueGrey[400], fontSize: 11)),
                  const SizedBox(height: 4),
                  Text("Déconnexion des WebSockets...", style: GoogleFonts.jetBrainsMono(color: Colors.blueGrey[400], fontSize: 11)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 900;

        return Scaffold(
          backgroundColor: const Color(0xFF070B14),
          body: Row(
            children: [
              if (isDesktop) _buildDesktopSidebar(),
              Expanded(
                child: Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutExpo,
                      switchOutCurve: Curves.easeInExpo,
                      child: _screens[_currentIndex],
                    ),
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

  Widget _buildDesktopSidebar() {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF131C2D),
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20)],
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // 🚀 LOGO INTÉGRÉ DANS LE HEADER DE LA SIDEBAR
          Container(
            width: 55,
            height: 55,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5))
            ),
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                  CupertinoIcons.waveform_path_ecg,
                  color: Color(0xFF00E5FF),
                  size: 28
              ),
            ),
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

          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: IconButton(
              icon: const Icon(CupertinoIcons.power, color: Colors.redAccent, size: 28),
              tooltip: "Déconnexion Sécurisée",
              onPressed: () => _executeSecureLogout(context),
            ),
          ),
        ],
      ),
    );
  }

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

class NavigationItem {
  final IconData icon;
  final String label;
  final Color? color;

  NavigationItem({required this.icon, required this.label, this.color});
}

// =====================================================================
// ÉCRAN D'ACCUEIL : HOME SUMMARY
// =====================================================================
class HomeSummaryView extends StatefulWidget {
  const HomeSummaryView({super.key});

  @override
  State<HomeSummaryView> createState() => _HomeSummaryViewState();
}

class _HomeSummaryViewState extends State<HomeSummaryView> with TickerProviderStateMixin {
  late AnimationController _bgLogoController;
  late AnimationController _orbController;
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Timer? _liveDataTimer;
  int _threatsBlocked = 1204;
  int _activeNodes = 42;
  final double _uptime = 99.98;

  @override
  void initState() {
    super.initState();
    _bgLogoController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _orbController = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutExpo));

    _entryController.forward();

    _liveDataTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      setState(() {
        _threatsBlocked += math.Random().nextInt(4);
        if (math.Random().nextBool()) {
          _activeNodes = 40 + math.Random().nextInt(6);
        }
      });
    });
  }

  @override
  void dispose() {
    _bgLogoController.dispose();
    _orbController.dispose();
    _entryController.dispose();
    _liveDataTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return ClipRect(
      child: Stack(
        children: [
          CustomPaint(
            size: Size(size.width, size.height),
            painter: CyberGridPainter(color: Colors.white.withValues(alpha: 0.03)),
          ),
          AnimatedBuilder(
              animation: _orbController,
              builder: (context, child) {
                final x1 = math.cos(_orbController.value * 2 * math.pi) * 150;
                final y1 = math.sin(_orbController.value * 2 * math.pi) * 150;
                final x2 = math.sin(_orbController.value * 2 * math.pi) * 200;
                final y2 = math.cos(_orbController.value * 2 * math.pi) * 200;

                return Stack(
                  children: [
                    Positioned(
                      top: (size.height * 0.2) + y1, left: (size.width * 0.2) + x1,
                      child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00E5FF).withValues(alpha: 0.08))),
                    ),
                    Positioned(
                      bottom: (size.height * 0.1) + y2, right: (size.width * 0.1) + x2,
                      child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF8B5CF6).withValues(alpha: 0.08))),
                    ),
                  ],
                );
              }
          ),
          Positioned.fill(
            child: AnimatedBuilder(
                animation: _bgLogoController,
                builder: (context, child) {
                  final dy = math.sin(_bgLogoController.value * 2 * math.pi) * 30;

                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: Opacity(
                      opacity: 0.04,
                      child: Center(
                        child: Image.asset(
                          'assets/logo.png',
                          width: 500,
                          height: 500,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                              CupertinoIcons.shield_lefthalf_fill,
                              size: 500,
                              color: Colors.white
                          ),
                        ),
                      ),
                    ),
                  );
                }
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
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
                              const Text("DARCK PULS CORE", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              Text("Tous les systèmes sont opérationnels.", style: TextStyle(color: Colors.blueGrey[400], fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),

                      const Text("VUE D'ENSEMBLE (LIVE NOC)", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
                                _buildStatCard("Uptime Réseau", "$_uptime%", CupertinoIcons.timer, const Color(0xFF00E5FF)),
                                _buildStatCard("Menaces Isolées", "$_threatsBlocked", CupertinoIcons.shield_lefthalf_fill, const Color(0xFFFF2A55)),
                                _buildStatCard("Nœuds Actifs", "$_activeNodes", Icons.dns, const Color(0xFF8B5CF6)),
                              ],
                            );
                          }
                      ),

                      const SizedBox(height: 48),

                      const Text("ACTIVITÉ RÉCENTE", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      const SizedBox(height: 16),
                      _buildActivityRow("Télémétrie IA : Aucune dérive critique détectée.", "En direct", CupertinoIcons.waveform_path_ecg),
                      _buildActivityRow("Synchronisation GitOps (Vault) réussie.", "Il y a 5 min", CupertinoIcons.cloud_upload),
                      _buildActivityRow("Analyse Wi-Fi de routine terminée.", "Il y a 12 min", CupertinoIcons.wifi),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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

class CyberGridPainter extends CustomPainter {
  final Color color;
  CyberGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double spacing = 40.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}