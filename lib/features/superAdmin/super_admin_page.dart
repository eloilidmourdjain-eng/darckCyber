import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:darck_puls/features/superAdmin/cyber_tools/widgets/defense_dashboard.dart';
import 'package:darck_puls/features/superAdmin/cyber_tools/widgets/offensive_panel.dart';
import 'package:darck_puls/features/superAdmin/screens/honeypot_monitor_page.dart';
import 'package:darck_puls/features/superAdmin/terminal/terminal_hub.dart';

class SuperAdminToolsPage extends StatefulWidget {
  const SuperAdminToolsPage({super.key});

  @override
  State<SuperAdminToolsPage> createState() => _SuperAdminToolsPageState();
}

class _SuperAdminToolsPageState extends State<SuperAdminToolsPage> with TickerProviderStateMixin {
  // --- THÈME CYBER ROOT (Red Alert) ---
  final Color kBackgroundColor = const Color(0xFF05000A); // Noir très profond avec reflet
  final Color kCardColor = const Color(0xFF130B1C);
  final Color kRootColor = const Color(0xFFFF2A55); // Rouge Néon (Privilège Root)
  final Color kTextMain = Colors.white;
  final Color kTextSecondary = const Color(0xFF94A3B8);

  late TabController _tabController;
  late AnimationController _pulseController;

  // États des daemons d'infrastructure
  bool _isN8nActive = true;
  bool _isVgpuBoostEnabled = true;
  bool _isHoneypotDefenseArmed = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildPremiumAppBar(),
            _buildGlassmorphismTabBar(),
            Expanded(
              // L'algorithme TabBarView gère le Lazy Loading des modules lourds
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(), // Désactive le swipe pour éviter les conflits avec le terminal ou les graphiques
                children: [
                  _buildBlueTeamSocTab(),    // 1. SOC, SIEM, vGPU, n8n
                  _buildDeceptionTab(),      // 2. Honeypots & Pièges
                  _buildOffensiveTab(),      // 3. Outils Offensifs (Pentest)
                  _buildRootTerminalTab(),   // 4. Console Native PTY
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // COMPOSANTS UI / UX PREMIUM
  // ==========================================

  Widget _buildPremiumAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: kBackgroundColor.withValues(alpha: 0.9),
        border: Border(bottom: BorderSide(color: kRootColor.withValues(alpha: 0.2))),
        boxShadow: [BoxShadow(color: kRootColor.withValues(alpha: 0.1), blurRadius: 20)],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(CupertinoIcons.back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Icon(CupertinoIcons.radiowaves_right, color: kRootColor.withValues(alpha: _pulseController.value), size: 24);
              }
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("SUPER ADMIN CONSOLE", style: TextStyle(color: kRootColor, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
               Text("Clearance Level : ROOT / DEVSECOPS", style: TextStyle(color: kTextSecondary, fontSize: 10, fontFamily: 'monospace')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphismTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicator: BoxDecoration(
              color: kRootColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kRootColor.withValues(alpha: 0.5)),
            ),
            labelColor: kRootColor,
            unselectedLabelColor: kTextSecondary,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            padding: const EdgeInsets.all(6),
            tabs: const [
              Tab(child: Row(children: [Icon(CupertinoIcons.shield_lefthalf_fill, size: 16), SizedBox(width: 8), Text("SOC & Infra")])),
              Tab(child: Row(children: [Icon(CupertinoIcons.cube_box_fill, size: 16), SizedBox(width: 8), Text("Honeypots")])),
              Tab(child: Row(children: [Icon(CupertinoIcons.flame_fill, size: 16), SizedBox(width: 8), Text("Red Team")])),
              Tab(child: Row(children: [Icon(Icons.terminal, size: 16), SizedBox(width: 8), Text("Root PTY")])),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ONGLET 1 : BLUE TEAM SOC & INFRASTRUCTURE
  // ==========================================
  Widget _buildBlueTeamSocTab() {
    return Column(
      children: [
        // Panneau de contrôle Infrastructure (vGPU & n8n)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.hub, color: Colors.orange, size: 18),
                          SizedBox(height: 4),
                          Text("n8n Auto", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      CupertinoSwitch(
                        activeTrackColor: Colors.orange,
                        value: _isN8nActive,
                        onChanged: (val) => setState(() => _isN8nActive = val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.withValues(alpha: 0.3))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.memory, color: Colors.amber, size: 18),
                          SizedBox(height: 4),
                          Text("vGPU Boost", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      CupertinoSwitch(
                        activeTrackColor: Colors.amber,
                        value: _isVgpuBoostEnabled,
                        onChanged: (val) => setState(() => _isVgpuBoostEnabled = val),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // INJECTION DU VRAI FICHIER SOC (La 10ème fenêtre)
        const Expanded(
          child: DefenseDashboardWidget(), // Ton fichier defense_dashboard.dart
        ),
      ],
    );
  }

  // ==========================================
  // ONGLET 2 : HONEYPOTS & DECEPTION
  // ==========================================
  Widget _buildDeceptionTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.4)), boxShadow: [BoxShadow(color: Colors.pinkAccent.withValues(alpha: 0.1), blurRadius: 20)]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(CupertinoIcons.cube_box_fill, color: Colors.pinkAccent, size: 18),
                        SizedBox(width: 8),
                        Text("Défense Active Armée", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text("4 Pièges Actifs : SSH Trap, FTP Fake...", style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
                CupertinoSwitch(value: _isHoneypotDefenseArmed, activeTrackColor: Colors.pinkAccent, onChanged: (val) => setState(() => _isHoneypotDefenseArmed = val)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // INJECTION DU VRAI FICHIER HONEYPOT
        const Expanded(
          child: HoneypotMonitorWidget(apiBaseUrl: "http://localhost:8080"), // Ton fichier honeypot_monitor_page.dart
        ),
      ],
    );
  }

  // ==========================================
  // ONGLET 3 : OFFENSIVE (RED TEAM)
  // ==========================================
  Widget _buildOffensiveTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: kRootColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: kRootColor.withValues(alpha: 0.3))),
            child:  Row(
              children: [
                Icon(CupertinoIcons.exclamationmark_triangle_fill, color: kRootColor, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text("Outils Offensifs : Assurez-vous d'avoir l'autorisation légale avant de lancer un scan ou un exploit.", style: TextStyle(color: kRootColor, fontSize: 11))),
              ],
            ),
          ),
        ),
        // INJECTION DU VRAI FICHIER OFFENSIF
        const Expanded(
          child: OffensiveActionPage(), // Ton fichier offensive_panel.dart
        ),
      ],
    );
  }

  // ==========================================
  // ONGLET 4 : TERMINAL ROOT NATIF
  // ==========================================
  Widget _buildRootTerminalTab() {
    return const Column(
      children: [
        // INJECTION DU VRAI TERMINAL HUB
        Expanded(
          child: TerminalHub(), // Ton fichier terminal_hub.dart
        ),
      ],
    );
  }
}
