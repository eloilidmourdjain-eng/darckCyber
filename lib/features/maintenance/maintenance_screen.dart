import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

// ==========================================
// MODÈLES DE DONNÉES SÉCURISÉS
// ==========================================
class ConfigBackup {
  final String id;
  final String timestamp;
  final String author;
  final String description;
  final bool isStable;
  ConfigBackup(this.id, this.timestamp, this.author, this.description, this.isStable);
}

class SystemLog {
  final String id;
  final String timestamp;
  final String event;
  final bool isImmutable; // True = Syslog externe, False = Note interne
  String? editableNote;

  SystemLog(this.id, this.timestamp, this.event, this.isImmutable, {this.editableNote});
}

class MaintenanceTask {
  final String title;
  final String scheduledTime;
  final String status;
  MaintenanceTask(this.title, this.scheduledTime, this.status);
}

// ==========================================
// ÉCRAN PRINCIPAL SRE & NETOPS
// ==========================================
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- ÉTATS : TÉLÉMÉTRIE ---
  double _cpuUsage = 45.0;
  double _ramUsage = 78.0;
  double _tempCelsius = 62.0;
  bool _isVastAiActive = false;
  late Timer _telemetryTimer;

  // --- ÉTATS : DIAGNOSTICS & LOGS ---
  bool _isRunningDiagnostics = false;
  double _diagnosticProgress = 0.0;
  bool _showImmutableLogs = true; // Toggle pour l'onglet Logs

  // --- BASES DE DONNÉES SIMULÉES ---
  final List<ConfigBackup> _backups = [
    ConfigBackup("v2.4.1", "Aujourd'hui, 04:30", "Auto-GitOps", "Snapshot WORM automatique", true),
    ConfigBackup("v2.4.0", "Hier, 14:15", "Admin (John)", "Correction BGP Route Leaks", true),
    ConfigBackup("v2.3.9", "20 Août 2026", "SuperAdmin", "Mise à jour Firmware Core", false),
  ];

  final List<MaintenanceTask> _tasks = [
    MaintenanceTask("Remplacement Switch Core-1", "Demain, 02:00 AM", "Planifié"),
    MaintenanceTask("Rotation des clés IPsec", "Dimanche, 00:00", "En attente d'approbation"),
  ];

  final List<SystemLog> _logs = [
    SystemLog("LOG-992", "10:45:01", "Port ETH-4 Flapping détecté (Hardware)", true),
    SystemLog("LOG-991", "10:40:00", "Note de Shift : Vérifier câble fibre optique Baie 2", false, editableNote: "Le technicien est en route. Attente de confirmation."),
    SystemLog("LOG-990", "09:12:44", "Admin_John s'est connecté via SSH", true),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Polling Télémétrie Sécurisé
    _telemetryTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        _cpuUsage = 40.0 + (DateTime.now().millisecond % 20);
        _tempCelsius = 60.0 + (DateTime.now().millisecond % 5);
      });
    });
  }

  @override
  void dispose() {
    _telemetryTimer.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // ==========================================
  // LOGIQUE MÉTIER (DevSecOps)
  // ==========================================
  void _runFullDiagnostics() async {
    if (_isRunningDiagnostics) return;
    setState(() { _isRunningDiagnostics = true; _diagnosticProgress = 0.0; });

    try {
      for (int i = 1; i <= 100; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
        if (!mounted) return;
        setState(() => _diagnosticProgress = i / 100);
      }
    } finally {
      if (mounted) {
        setState(() => _isRunningDiagnostics = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.greenAccent, content: Text("Diagnostic terminé : Réseau Sain.", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))));
      }
    }
  }

  void _executeRollback(ConfigBackup backup) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Application de la config ${backup.id} en cours...")));
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.purpleAccent, content: Text("Réseau restauré avec succès !")));
  }

  // ==========================================
  // STRUCTURE PRINCIPALE DE L'INTERFACE
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B14),
        elevation: 0,
        title: const Text('Centre SRE & Opérations IT', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF00E5FF),
          labelColor: const Color(0xFF00E5FF),
          unselectedLabelColor: Colors.blueGrey[600],
          tabs: const [
            Tab(icon: Icon(CupertinoIcons.speedometer, size: 18), text: "Télémétrie"),
            Tab(icon: Icon(CupertinoIcons.archivebox_fill, size: 18), text: "Config Vault"),
            Tab(icon: Icon(CupertinoIcons.waveform_path_ecg, size: 18), text: "Diagnostics"),
            Tab(icon: Icon(CupertinoIcons.calendar, size: 18), text: "Planification"),
            Tab(icon: Icon(CupertinoIcons.doc_text_fill, size: 18), text: "Audit Logs"),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTelemetryTab(),
            _buildConfigVaultTab(),
            _buildDiagnosticsTab(),
            _buildSchedulerTab(),
            _buildLogsTab(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ONGLET 1 : TÉLÉMÉTRIE & VAST.AI AIOps
  // ==========================================
  Widget _buildTelemetryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Santé Matérielle (Live)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          LayoutBuilder(
              builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 600;
                return Flex(
                  direction: isMobile ? Axis.vertical : Axis.horizontal,
                  children: [
                    Expanded(flex: isMobile ? 0 : 1, child: _buildGauge("CPU", _cpuUsage, "%", Colors.cyanAccent)),
                    if (isMobile) const SizedBox(height: 16) else const SizedBox(width: 16),
                    Expanded(flex: isMobile ? 0 : 1, child: _buildGauge("NVRAM", _ramUsage, "%", Colors.purpleAccent)),
                    if (isMobile) const SizedBox(height: 16) else const SizedBox(width: 16),
                    Expanded(flex: isMobile ? 0 : 1, child: _buildGauge("Température", _tempCelsius, "°C", _tempCelsius > 70 ? Colors.redAccent : Colors.orangeAccent)),
                  ],
                );
              }
          ),
          const SizedBox(height: 32),

          // VAST.AI INTEGRATION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("AIOps & Vast.ai Integration", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              CupertinoSwitch(
                  value: _isVastAiActive,
                  activeTrackColor: const Color(0xFF8B5CF6),
                  onChanged: (val) => setState(() => _isVastAiActive = val)
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF131C2D), borderRadius: BorderRadius.circular(16), border: Border.all(color: _isVastAiActive ? const Color(0xFF8B5CF6) : Colors.white10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isVastAiActive ? "Délégation Cloud Active : Analyse des logs matériels par IA en cours." : "AIOps désactivé. Analyse matérielle locale uniquement.", style: TextStyle(color: Colors.blueGrey[300], fontSize: 12)),
                const SizedBox(height: 16),
                // Alerte Prédictive
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.orangeAccent, size: 20),
                          SizedBox(width: 10),
                          Text("Alerte Prédictive (Port ETH-4)", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Augmentation des erreurs CRC détectée. Dégradation du module SFP imminente.", style: TextStyle(color: Colors.orange[200], fontSize: 12)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black, minimumSize: const Size(0, 36)), onPressed: () {}, child: const Text("Isoler le port", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                          const SizedBox(width: 8),
                          OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor: Colors.white70, minimumSize: const Size(0, 36)), onPressed: () {}, child: const Text("Ignorer", style: TextStyle(fontSize: 11))),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGauge(String title, double value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF131C2D), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.blueGrey[300], fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(width: 70, height: 70, child: CircularProgressIndicator(value: value / 100, strokeWidth: 6, backgroundColor: Colors.white.withValues(alpha: 0.05), color: color, strokeCap: StrokeCap.round)),
              Text("${value.toInt()}$unit", style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ONGLET 2 : CONFIG VAULT (GITOPS)
  // ==========================================
  Widget _buildConfigVaultTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _backups.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Dépôt Sécurisé (GitOps)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF131C2D), foregroundColor: const Color(0xFF00E5FF)),
                  icon: const Icon(CupertinoIcons.cloud_upload, size: 16), label: const Text("Snapshot Manuel"), onPressed: () {},
                )
              ],
            ),
          );
        }
        final backup = _backups[index - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF131C2D), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(backup.isStable ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.exclamationmark_circle_fill, color: backup.isStable ? Colors.greenAccent : Colors.redAccent, size: 20),
                  const SizedBox(width: 12),
                  Text(backup.id, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  Text(backup.timestamp, style: TextStyle(color: Colors.blueGrey[500], fontSize: 10)),
                ],
              ),
              const SizedBox(height: 8),
              Text(backup.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blueGrey), foregroundColor: Colors.blueGrey, minimumSize: const Size(0, 32)),
                    icon: const Icon(CupertinoIcons.doc_text_search, size: 14), label: const Text("Voir le Diff", style: TextStyle(fontSize: 11)), onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withValues(alpha: 0.2), foregroundColor: Colors.redAccent, minimumSize: const Size(0, 32), elevation: 0),
                    icon: const Icon(CupertinoIcons.arrow_counterclockwise, size: 14), label: const Text("Rollback", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      // Simule l'approbation MFA avant le rollback
                      showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: const Color(0xFF131C2D), title: const Text("Approbation requise", style: TextStyle(color: Colors.redAccent)),
                            content: const Text("Le Rollback nécessite une validation 2FA de l'administrateur système.", style: TextStyle(color: Colors.white70)),
                            actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Annuler")), ElevatedButton(onPressed: (){Navigator.pop(ctx); _executeRollback(backup);}, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text("Autoriser"))],
                          )
                      );
                    },
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // ONGLET 3 : DIAGNOSTICS RÉSEAU
  // ==========================================
  Widget _buildDiagnosticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF131C2D), Color(0xFF070B14)]), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3))),
            child: Column(
              children: [
                const Icon(CupertinoIcons.waveform_path_ecg, color: Color(0xFF00E5FF), size: 40),
                const SizedBox(height: 16),
                const Text("Diagnostic Deep-Dive", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Inspection BGP, Latence DNS, Jitter et perte de paquets.", textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey[400], fontSize: 12)),
                const SizedBox(height: 24),
                if (_isRunningDiagnostics) ...[
                  LinearProgressIndicator(value: _diagnosticProgress, backgroundColor: Colors.white.withValues(alpha: 0.05), color: const Color(0xFF00E5FF), minHeight: 6, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(height: 8),
                  Text("Scan en cours... ${(_diagnosticProgress * 100).toInt()}%", style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11)),
                ] else
                  SizedBox(width: double.infinity, height: 45, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black), onPressed: _runFullDiagnostics, child: const Text("LANCER LE DIAGNOSTIC", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text("Applications Recommandées (Boîte à outils)", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildToolBoxItem("Wireshark", "Capture et analyse profonde de paquets (PCAP).", CupertinoIcons.waveform_path),
          _buildToolBoxItem("iPerf3", "Test de bande passante et débit TCP/UDP.", CupertinoIcons.speedometer),
          _buildToolBoxItem("MTR (My Traceroute)", "Diagnostic réseau dynamique combinant ping et traceroute.", CupertinoIcons.arrow_branch),
        ],
      ),
    );
  }

  Widget _buildToolBoxItem(String title, String desc, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF131C2D), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey[300], size: 24),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)), Text(desc, style: TextStyle(color: Colors.blueGrey[500], fontSize: 11))])),
          const Icon(CupertinoIcons.cloud_download, color: Color(0xFF00E5FF), size: 16)
        ],
      ),
    );
  }

  // ==========================================
  // ONGLET 4 : PLANIFICATION
  // ==========================================
  Widget _buildSchedulerTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _tasks.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(CupertinoIcons.calendar_badge_plus, color: Colors.white), label: const Text("Programmer une maintenance (CRON)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), onPressed: () {},
            ),
          );
        }
        final task = _tasks[index - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF131C2D), border: Border(left: BorderSide(color: task.status == "Planifié" ? Colors.greenAccent : Colors.orangeAccent, width: 4))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [const Icon(CupertinoIcons.time, color: Colors.blueGrey, size: 14), const SizedBox(width: 4), Text(task.scheduledTime, style: TextStyle(color: Colors.blueGrey[300], fontSize: 11))]),
                  Text(task.status, style: TextStyle(color: task.status == "Planifié" ? Colors.greenAccent : Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // ONGLET 5 : AUDIT LOGS (Éditables vs WORM)
  // ==========================================
  Widget _buildLogsTab() {
    List<SystemLog> displayLogs = _logs.where((log) => log.isImmutable == _showImmutableLogs).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Expanded(
                child: CupertinoSlidingSegmentedControl<bool>(
                  groupValue: _showImmutableLogs,
                  backgroundColor: const Color(0xFF131C2D),
                  thumbColor: const Color(0xFF3B82F6),
                  children: const {
                    true: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text("Syslogs (Immuable)", style: TextStyle(color: Colors.white, fontSize: 12))),
                    false: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text("Notes d'Équipe (Éditable)", style: TextStyle(color: Colors.white, fontSize: 12))),
                  },
                  onValueChanged: (val) => setState(() => _showImmutableLogs = val!),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(icon: const Icon(CupertinoIcons.tray_arrow_down, color: Color(0xFF00E5FF)), tooltip: "Exporter (PDF/CSV)", onPressed: () {}),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          color: _showImmutableLogs ? Colors.redAccent.withValues(alpha: 0.1) : Colors.transparent,
          child: Text(
            _showImmutableLogs ? "⚠️ Ces journaux sont scellés cryptographiquement. Aucune modification n'est permise." : "📝 Ces notes sont partagées avec l'équipe pour la passation de service (Shift).",
            style: TextStyle(color: _showImmutableLogs ? Colors.redAccent : Colors.blueGrey[400], fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: displayLogs.length,
            itemBuilder: (context, index) {
              final log = displayLogs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF131C2D), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(log.id, style: GoogleFonts.jetBrainsMono(color: _showImmutableLogs ? Colors.redAccent : const Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(log.timestamp, style: GoogleFonts.jetBrainsMono(color: Colors.blueGrey[500], fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(log.event, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    if (!log.isImmutable && log.editableNote != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.3))),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(CupertinoIcons.pencil, color: Colors.blueGrey, size: 14),
                            const SizedBox(width: 8),
                            Expanded(child: Text(log.editableNote!, style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic))),
                          ],
                        ),
                      )
                    ]
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }
}