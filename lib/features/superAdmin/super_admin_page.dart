import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

import 'package:darck_puls/features/superAdmin/cyber_tools/widgets/defense_dashboard.dart';
import 'package:darck_puls/features/superAdmin/cyber_tools/widgets/offensive_panel.dart';
import 'package:darck_puls/features/superAdmin/screens/honeypot_monitor_page.dart';

// --- NOUVEAU MODÈLE POUR LE BASTION LINUX ---
class LinuxBastionNode {
  final String name;
  final String ip;
  final String user;
  final String osDistro;
  bool isConnected;

  LinuxBastionNode(this.name, this.ip, this.user, this.osDistro, {this.isConnected = false});
}

class SuperAdminToolsPage extends StatefulWidget {
  const SuperAdminToolsPage({super.key});

  @override
  State<SuperAdminToolsPage> createState() => _SuperAdminToolsPageState();
}

class _SuperAdminToolsPageState extends State<SuperAdminToolsPage> with TickerProviderStateMixin {
  // --- THÈME CYBER ROOT (Red Alert) ---
  final Color kBackgroundColor = const Color(0xFF05000A);
  final Color kCardColor = const Color(0xFF130B1C);
  final Color kRootColor = const Color(0xFFFF2A55);
  final Color kTextSecondary = const Color(0xFF94A3B8);
  final Color kRed = const Color(0xFFFF2A55);

  late TabController _tabController;
  late AnimationController _pulseController;

  // États des daemons d'infrastructure
  bool _isN8nActive = true;
  bool _isVgpuBoostEnabled = true;
  bool _isHoneypotDefenseArmed = true;

  // État du Bastion Linux (Nouvel Onglet 4)
  final List<LinuxBastionNode> _bastionNodes = [];
  final List<String> _bastionAuditLogs = [];
  final TextEditingController _sshCommandController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);

    // Ajout d'une machine simulée pour le design
    _bastionNodes.add(LinuxBastionNode("Kali-Ops-01", "10.0.0.99", "root", "Kali Linux", isConnected: true));
    _bastionAuditLogs.add("[SYS] Authentification par clé réussie vers 10.0.0.99");
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _sshCommandController.dispose();
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
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildBlueTeamSocTab(),    // 1. SOC, SIEM, vGPU, n8n
                  _buildDeceptionTab(),      // 2. Honeypots & Pièges
                  _buildOffensiveTab(),      // 3. Outils Offensifs (Pentest)
                  _buildLinuxBastionTab(),   // 4. NOUVEAU: Pont Linux / Bastion Audit
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
              Tab(child: Row(children: [Icon(CupertinoIcons.link, size: 16), SizedBox(width: 8), Text("Pont Linux")])), // Onglet modifié
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
        const Expanded(child: DefenseDashboardWidget()),
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
        const Expanded(child: HoneypotMonitorWidget(apiBaseUrl: "http://localhost:8080")),
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
            child: Row(
              children: [
                Icon(CupertinoIcons.exclamationmark_triangle_fill, color: kRootColor, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text("Outils Offensifs : Assurez-vous d'avoir l'autorisation légale avant de lancer un scan ou un exploit.", style: TextStyle(color: kRootColor, fontSize: 11))),
              ],
            ),
          ),
        ),
        const Expanded(child: OffensiveActionPage()),
      ],
    );
  }

  // ==========================================
  // ONGLET 4 : LE PONT LINUX (BASTION HOST)
  // ==========================================
  Widget _buildLinuxBastionTab() {
    // Vérification de la plateforme (Mobile vs Desktop)
    bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kCardColor, const Color(0xFF000000)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("PONT LINUX (BASTION HOST)", style: TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Supervision et exécution via tunnel SSH isolé.", style: TextStyle(color: Colors.blueGrey[400], fontSize: 11)),
                  ],
                ),
                ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent.withValues(alpha: 0.2), foregroundColor: Colors.greenAccent),
                    onPressed: () {
                      // Logique pour ajouter une machine (Ouvre un modal pour IP/User/Clé)
                    },
                    icon: const Icon(CupertinoIcons.add, size: 14),
                    label: const Text("Associer Node")
                )
              ],
            ),
          ),
        ),

        // Liste des machines connectées
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _bastionNodes.length,
            itemBuilder: (context, index) {
              final node = _bastionNodes[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(CupertinoIcons.device_laptop, color: Colors.greenAccent, size: 20)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(node.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text("${node.user}@${node.ip} • ${node.osDistro}", style: TextStyle(color: Colors.blueGrey[400], fontSize: 11, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: node.isConnected ? Colors.greenAccent.withValues(alpha: 0.1) : kRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text(node.isConnected ? "SECURE TUNNEL" : "OFFLINE", style: TextStyle(color: node.isConnected ? Colors.greenAccent : kRed, fontSize: 10, fontWeight: FontWeight.bold))),
                  ],
                ),
              );
            },
          ),
        ),

        // Zone d'exécution (Différente selon Desktop ou Mobile)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isMobile ? _buildMobileBastionTerminal() : _buildDesktopBastionInstructions(),
          ),
        ),
      ],
    );
  }

  // --- RENDU MOBILE : TERMINAL D'AUDIT SÉCURISÉ ---
  Widget _buildMobileBastionTerminal() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF000000), // Noir Matrix
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF130B1C), borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
            child: Row(
              children: [
                const Icon(CupertinoIcons.circle_fill, color: Colors.redAccent, size: 10), const SizedBox(width: 6),
                const Icon(CupertinoIcons.circle_fill, color: Colors.orangeAccent, size: 10), const SizedBox(width: 6),
                const Icon(CupertinoIcons.circle_fill, color: Colors.greenAccent, size: 10), const SizedBox(width: 12),
                const Text("Proxy Terminal (Audited)", style: TextStyle(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _bastionAuditLogs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(_bastionAuditLogs[index], style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace')),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: kCardColor, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12))),
            child: TextField(
              controller: _sshCommandController,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(hintText: "root@Kali-Ops-01:~#", hintStyle: TextStyle(color: Colors.white30), border: InputBorder.none),
              onSubmitted: (cmd) {
                if (cmd.trim().isEmpty) return;
                setState(() {
                  _bastionAuditLogs.add("root@Kali-Ops-01:~# $cmd");
                  _bastionAuditLogs.add("[AUDIT] Action enregistrée. Traitement par le tunnel...");
                });
                _sshCommandController.clear();
              },
            ),
          )
        ],
      ),
    );
  }

  // --- RENDU DESKTOP : INSTRUCTIONS (Pas de terminal natif dans l'app) ---
  Widget _buildDesktopBastionInstructions() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: kCardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), style: BorderStyle.solid),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.device_desktop, color: Colors.blueGrey, size: 64),
            const SizedBox(height: 24),
            const Text("ENVIRONNEMENT DESKTOP DÉTECTÉ", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text("Pour des raisons de sécurité (Sandboxing de l'OS), l'émulation du terminal SSH est désactivée sur les applications de bureau.", textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey, fontSize: 12, height: 1.5)),
            const SizedBox(height: 32),
            const Text("Veuillez utiliser votre terminal natif (PowerShell, iTerm, Terminator) avec la commande suivante :", style: TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3))),
              child: const SelectableText(
                "ssh -i ~/.ssh/darkpulse_ed25519 root@10.0.0.99",
                style: TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}