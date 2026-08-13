import 'dart:async';
import 'package:flutter/material.dart';

// Constantes de design issues du Dashboard principal
const Color kBackgroundColor = Color(0xFF0F172A);
const Color kCardColor = Color(0xFF1E293B);
const Color kAccentColor = Color(0xFF38BDF8);
const Color kTextMain = Colors.white;
const Color kTextSecondary = Color(0xFF94A3B8);

class SuperAdminToolsPage extends StatefulWidget {
  const SuperAdminToolsPage({super.key});

  @override
  State<SuperAdminToolsPage> createState() => _SuperAdminToolsPageState();
}

class _SuperAdminToolsPageState extends State<SuperAdminToolsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // États pour les modules de contrôle
  bool _isN8nActive = true;
  bool _isVgpuBoostEnabled = true;
  bool _isHoneypotDefenseArmed = true;
  final TextEditingController _terminalController = TextEditingController();
  final List<String> _terminalLogs = [
    "[SYSTEM_INIT] Connexion au démon sécurisé v2.5 établie.",
    "[INFO] Surveillance des flux active sur les ports critiques.",
    "[READY] En attente de commandes root ou de scripts d'automatisation..."
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _terminalController.dispose();
    super.dispose();
  }

  void _executeTerminalCommand(String cmd) {
    if (cmd.trim().isEmpty) return;
    setState(() {
      _terminalLogs.add("root@darckcyber-node:~# $cmd");
      if (cmd.contains("clear")) {
        _terminalLogs.clear();
      } else if (cmd.contains("status")) {
        _terminalLogs.add("[STATUS] vGPU: OK | n8n: RUNNING | Pots de Miel: 4 Actifs");
      } else {
        _terminalLogs.add("[EXEC] Commande exécutée avec succès dans l'environnement isolé.");
      }
    });
    _terminalController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kCardColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.redAccent),
        title: const Text(
          "CONSOLE SUPER ADMIN & MODULES",
          style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.redAccent,
          unselectedLabelColor: kTextSecondary,
          indicatorColor: Colors.redAccent,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.terminal, size: 18), text: "Console Root"),
            Tab(icon: Icon(Icons.hub, size: 18), text: "n8n Automation"),
            Tab(icon: Icon(Icons.memory, size: 18), text: "vGPU & RAM"),
            Tab(icon: Icon(Icons.security, size: 18), text: "Pots de Miel"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // =================================================================
          // ONGLET 1 : CONSOLE ROOT & TERMINAL SÉCURISÉ
          // =================================================================
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Zone Hautement Sensible : Toutes les actions exécutées ici sont journalisées et audités.",
                          style: TextStyle(color: Colors.redAccent, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kCardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: ListView.builder(
                      itemCount: _terminalLogs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            _terminalLogs[index],
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontFamily: 'monospace'),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _terminalController,
                        style: const TextStyle(color: kTextMain, fontSize: 12, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          hintText: "Entrer une commande (ex: status, clear)...",
                          hintStyle: const TextStyle(color: kTextSecondary, fontSize: 11),
                          filled: true,
                          fillColor: kCardColor,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        onSubmitted: (val) => _executeTerminalCommand(val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                      onPressed: () => _executeTerminalCommand(_terminalController.text),
                      child: const Text("Exécuter"),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // =================================================================
          // ONGLET 2 : PIPELINE N8N AUTOMATION
          // =================================================================
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text("GESTION DES PIPELINES D'AUTOMATISATION N8N", style: TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.hub, color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Text("Démon n8n Automation", style: TextStyle(color: kTextMain, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Switch(
                          value: _isN8nActive,
                          activeThumbColor: Colors.orange,
                          onChanged: (val) {
                            setState(() {
                              _isN8nActive = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    const Text("Statut : Actif sur le port 5678", style: TextStyle(color: Colors.green, fontSize: 11)),
                    const SizedBox(height: 6),
                    const Text("Workflows connectés : Alertes de sécurité, synchronisation des logs Python IMMRED, et rapports d'incidents.", style: TextStyle(color: kTextSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),

          // =================================================================
          // ONGLET 3 : SUPERVISION VGPU & RAM
          // =================================================================
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text("RESSOURCES MATÉRIELLES ET ACCÉLÉRATION", style: TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.memory, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text("Allocation vGPU & Mémoire RAM", style: TextStyle(color: kTextMain, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    const Text("Utilisation vGPU : 68% (NVIDIA CUDA Core Actifs)", style: TextStyle(color: kTextMain, fontSize: 12)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: 0.68, backgroundColor: Colors.white12, color: Colors.amber),
                    const SizedBox(height: 14),
                    const Text("Mémoire RAM Allouée : 12.4 Go / 16 Go", style: TextStyle(color: kTextMain, fontSize: 12)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: 0.77, backgroundColor: Colors.white12, color: Colors.blueAccent),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Activer le mode Boost vGPU", style: TextStyle(color: kTextMain, fontSize: 12)),
                      value: _isVgpuBoostEnabled,
                      activeThumbColor: Colors.amber,
                      onChanged: (val) {
                        setState(() {
                          _isVgpuBoostEnabled = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // =================================================================
          // ONGLET 4 : POTS DE MIEL (HONEYPOTS)
          // =================================================================
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text("SURVEILLANCE ET PIÉGEAGE DESATTAQUES", style: TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.security, color: Colors.pinkAccent, size: 20),
                            SizedBox(width: 8),
                            Text("Défense active Honeypots", style: TextStyle(color: kTextMain, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Switch(
                          value: _isHoneypotDefenseArmed,
                          activeThumbColor: Colors.pinkAccent,
                          onChanged: (val) {
                            setState(() {
                              _isHoneypotDefenseArmed = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    const Text("4 Pièges Actifs : SSH Trap, FTP Fake Server, Web Admin Bait, Database Honeytoken.", style: TextStyle(color: kTextSecondary, fontSize: 11)),
                    const SizedBox(height: 10),
                    const Text("Attaques interceptées aujourd'hui : 34 (IPs bloquées automatiquement).", style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}