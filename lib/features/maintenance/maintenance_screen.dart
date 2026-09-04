import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';


// --- MODÈLES DE DONNÉES ---
class ConfigBackup {
  final String id;
  final String timestamp;
  final String author;
  final String description;
  final bool isStable;
  ConfigBackup(this.id, this.timestamp, this.author, this.description, this.isStable);
}

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({Key? key}) : super(key: key);

  @override
  _MaintenanceScreenState createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  // --- VARIABLES D'ÉTAT ---
  bool _isRunningDiagnostics = false;
  double _diagnosticProgress = 0.0;

  double _cpuUsage = 45.0;
  double _ramUsage = 78.0;
  double _tempCelsius = 62.0;

  final List<ConfigBackup> _backups = [
    ConfigBackup("v2.4.1", "Aujourd'hui, 04:30 AM", "Auto-Backup", "Sauvegarde quotidienne", true),
    ConfigBackup("v2.4.0", "Hier, 14:15 PM", "Admin (John)", "Ajout VLAN 20 (Compta)", true),
    ConfigBackup("v2.3.9", "20 Août 2026", "SuperAdmin", "Mise à jour Firmware OSPF", true),
  ];

  late Timer _telemetryTimer;

  @override
  void initState() {
    super.initState();
    // Polling sécurisé avec vérification du montage
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
    super.dispose();
  }

  // --- MOTEUR DE DIAGNOSTIC GLOBAL SÉCURISÉ ---
  void _runFullDiagnostics() async {
    if (_isRunningDiagnostics) return;

    setState(() {
      _isRunningDiagnostics = true;
      _diagnosticProgress = 0.0;
    });

    try {
      for (int i = 1; i <= 100; i++) {
        await Future.delayed(const Duration(milliseconds: 30));
        if (!mounted) return; // Sécurité anti-crash si l'écran est fermé
        setState(() => _diagnosticProgress = i / 100);
      }
    } finally {
      if (mounted) {
        setState(() => _isRunningDiagnostics = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.greenAccent,
            content: Text(
              "Diagnostic terminé : 0 erreur critique, 1 avertissement CRC.",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    }
  }

  // --- ROLLBACK SÉCURISÉ AVEC VALIDATION ADMIN ---
  void _rollbackConfig(ConfigBackup backup) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Confirmation de Sécurité", style: TextStyle(color: Colors.white)),
        content: Text(
          "Voulez-vous vraiment restaurer la version ${backup.id} ? Cette action modifiera la table de routage en production.",
          style: const TextStyle(color: Colors.blueGrey),
        ),
        actions: [
          TextButton(
            child: const Text("Annuler", style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Confirmer le Rollback", style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.of(context).pop();
              _executeRollback(backup);
            },
          ),
        ],
      ),
    );
  }

  void _executeRollback(ConfigBackup backup) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Restauration sécurisée de la version ${backup.id} en cours...")),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.purpleAccent,
        content: Text("Réseau restauré et synchronisé avec succès !"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Maintenance & SRE (NetOps)', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Santé matérielle, sauvegardes et diagnostics prédictifs.', style: TextStyle(color: Colors.blueGrey[400], fontSize: 14)),
              const SizedBox(height: 32),

              // 1. HEALTH DASHBOARD
              const Text("Télémétrie Matérielle (Live)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              LayoutBuilder(
                  builder: (context, constraints) {
                    bool isMobile = constraints.maxWidth < 600;
                    return Flex(
                      direction: isMobile ? Axis.vertical : Axis.horizontal,
                      children: [
                        Expanded(flex: isMobile ? 0 : 1, child: _buildTelemetryGauge("CPU", _cpuUsage, " %", Colors.cyanAccent)),
                        if (isMobile) const SizedBox(height: 16) else const SizedBox(width: 16),
                        Expanded(flex: isMobile ? 0 : 1, child: _buildTelemetryGauge("RAM (NVRAM)", _ramUsage, " %", Colors.purpleAccent)),
                        if (isMobile) const SizedBox(height: 16) else const SizedBox(width: 16),
                        Expanded(flex: isMobile ? 0 : 1, child: _buildTelemetryGauge("Température", _tempCelsius, " °C", _tempCelsius > 70 ? Colors.redAccent : Colors.orangeAccent)),
                      ],
                    );
                  }
              ),
              const SizedBox(height: 32),

              // 2. MAINTENANCE PRÉDICTIVE
              const Text("AIOps - Maintenance Prédictive", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildPredictiveAlert(),
              const SizedBox(height: 32),

              // 3. CONFIG VAULT
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Config Vault (GitOps)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(CupertinoIcons.cloud_upload, color: Colors.cyanAccent, size: 16),
                    label: const Text("Forcer Sauvegarde", style: TextStyle(color: Colors.cyanAccent)),
                  )
                ],
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _backups.length,
                itemBuilder: (context, index) => _buildBackupTile(_backups[index]),
              ),
              const SizedBox(height: 32),

              // 4. MOTEUR DE DIAGNOSTIC
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    const Icon(CupertinoIcons.waveform_path_ecg, color: Colors.greenAccent, size: 48),
                    const SizedBox(height: 16),
                    const Text("Diagnostic Réseau Approfondi", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Analyse des tables de routage, vérification SFP/Optique, et latence DNS.", textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey[400], fontSize: 12)),
                    const SizedBox(height: 24),
                    if (_isRunningDiagnostics) ...[
                      LinearProgressIndicator(value: _diagnosticProgress, backgroundColor: Colors.white10, color: Colors.greenAccent, minHeight: 8, borderRadius: BorderRadius.circular(4)),
                      const SizedBox(height: 8),
                      Text("Analyse en cours... ${(_diagnosticProgress * 100).toInt()}%", style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                    ] else
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent.withOpacity(0.2),
                            foregroundColor: Colors.greenAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: Colors.greenAccent),
                          ),
                          onPressed: _runFullDiagnostics,
                          child: const Text("Lancer le Scan de Maintenance", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryGauge(String title, double value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.blueGrey[300], fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: value / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text("${value.toInt()}$unit", style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPredictiveAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.orangeAccent, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Anomalie Optique (Port ETH-4)", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text("L'IA détecte une augmentation des erreurs CRC (Cyclic Redundancy Check) de 15% sur les 48 dernières heures. Remplacement du module SFP recommandé sous 7 jours.", style: TextStyle(color: Colors.orange[200], fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBackupTile(ConfigBackup backup) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
            child: Icon(backup.isStable ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.exclamationmark_circle_fill, color: backup.isStable ? Colors.greenAccent : Colors.redAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(backup.id, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 8),
                    Text("par ${backup.author}", style: TextStyle(color: Colors.blueGrey[400], fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(backup.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Text(backup.timestamp, style: TextStyle(color: Colors.blueGrey[500], fontSize: 10)),
              ],
            ),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.purpleAccent),
              foregroundColor: Colors.purpleAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(CupertinoIcons.arrow_counterclockwise, size: 14),
            label: const Text("Rollback", style: TextStyle(fontSize: 12)),
            onPressed: () => _rollbackConfig(backup),
          )
        ],
      ),
    );
  }
}
