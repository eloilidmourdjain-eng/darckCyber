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
  final bool isImmutable;
  String? editableNote;

  SystemLog(this.id, this.timestamp, this.event, this.isImmutable, {this.editableNote});
}

class MaintenanceTask {
  final String title;
  final String scheduledTime;
  final String status;
  MaintenanceTask(this.title, this.scheduledTime, this.status);
}

// Niveaux d'alerte pour le Dashboard SRE
enum AlertSeverity { info, warning, critical }

// ==========================================
// ÉCRAN PRINCIPAL SRE & NETOPS
// ==========================================
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> with TickerProviderStateMixin {
late TabController _tabController;
late AnimationController _pulseController;

// --- ÉTATS : TÉLÉMÉTRIE ---
double _cpuUsage = 45.0;
double _ramUsage = 78.0;
double _tempCelsius = 62.0;
bool _isVastAiActive = false;
late Timer _telemetryTimer;

// --- ÉTATS : DIAGNOSTICS & LOGS ---
bool _isRunningDiagnostics = false;
double _diagnosticProgress = 0.0;
bool _showImmutableLogs = true;
String? _diagnosticAlert; // Pour simuler une alerte après le scan

// --- BASES DE DONNÉES SIMULÉES ---
final List<ConfigBackup> _backups = [
ConfigBackup("v2.4.1", "Aujourd'hui, 04:30", "Auto-GitOps", "Snapshot WORM automatique", false), // Simule une instabilité
ConfigBackup("v2.4.0", "Hier, 14:15", "Admin (John)", "Correction BGP Route Leaks", true),
ConfigBackup("v2.3.9", "20 Août 2026", "SuperAdmin", "Mise à jour Firmware Core", true),
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

// Animation pour les alertes critiques
_pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);

// Polling Télémétrie Sécurisé
_telemetryTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
if (!mounted) return;
setState(() {
_cpuUsage = 40.0 + (DateTime.now().millisecond % 20);
// Simulation d'une surchauffe périodique pour déclencher l'alerte CRITICAL
_tempCelsius = timer.tick % 10 == 0 ? 82.0 : 60.0 + (DateTime.now().millisecond % 5);
});
});
}

@override
void dispose() {
_telemetryTimer.cancel();
_pulseController.dispose();
_tabController.dispose();
super.dispose();
}

// ==========================================
// LOGIQUE MÉTIER (DevSecOps)
// ==========================================
void _runFullDiagnostics() async {
if (_isRunningDiagnostics) return;
setState(() {
_isRunningDiagnostics = true;
_diagnosticProgress = 0.0;
_diagnosticAlert = null;
});

try {
for (int i = 1; i <= 100; i++) {
await Future.delayed(const Duration(milliseconds: 20));
if (!mounted) return;
setState(() => _diagnosticProgress = i / 100);
}
} finally {
if (mounted) {
setState(() {
_isRunningDiagnostics = false;
_diagnosticAlert = "Latence BGP détectée sur le lien WAN-2 (Jitter: 45ms).";
});
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
// SYSTÈME DE NOTIFICATION UI/UX PREMIUM
// ==========================================
Widget _buildCyberAlertBanner(String title, String message, AlertSeverity severity) {
Color accentColor;
IconData icon;
bool isPulsing = false;

switch (severity) {
case AlertSeverity.critical:
accentColor = const Color(0xFFFF2A55); // Rouge Néon
icon = CupertinoIcons.exclamationmark_triangle_fill;
isPulsing = true;
break;
case AlertSeverity.warning:
accentColor = Colors.orangeAccent;
icon = CupertinoIcons.exclamationmark_shield_fill;
break;
case AlertSeverity.info:
default:
accentColor = const Color(0xFF00E5FF); // Cyan
icon = CupertinoIcons.info_circle_fill;
}

Widget alertContent = Container(
margin: const EdgeInsets.only(bottom: 24),
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: const Color(0xFF131C2D),
borderRadius: BorderRadius.circular(12),
border: Border(left: BorderSide(color: accentColor, width: 4)),
boxShadow: isPulsing ? [BoxShadow(color: accentColor.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: -2)] : [],
),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Icon(icon, color: accentColor, size: 24),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(title, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
const SizedBox(height: 4),
Text(message, style: TextStyle(color: Colors.blueGrey[300], fontSize: 11, height: 1.4)),
],
),
),
if (severity != AlertSeverity.info)
IconButton(
icon: const Icon(CupertinoIcons.clear_circled, size: 16, color: Colors.blueGrey),
onPressed: () {}, // Simule l'acquittement de l'alerte
padding: EdgeInsets.zero,
constraints: const BoxConstraints(),
)
],
),
);

if (isPulsing) {
return AnimatedBuilder(
animation: _pulseController,
builder: (context, child) {
return Transform.scale(
scale: 1.0 + (_pulseController.value * 0.01), // Micro-pulsation UI
child: alertContent,
);
}
);
}
return alertContent;
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
title: const Text('Centre SRE & Opérations IT', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
bottom: TabBar(
controller: _tabController,
isScrollable: true,
indicatorColor: const Color(0xFF00E5FF),
labelColor: const Color(0xFF00E5FF),
unselectedLabelColor: Colors.blueGrey[600],
labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
// ONGLET 1 : TÉLÉMÉTRIE
// ==========================================
Widget _buildTelemetryTab() {
bool isOverheating = _tempCelsius >= 75.0;

return SingleChildScrollView(
physics: const BouncingScrollPhysics(),
padding: const EdgeInsets.all(24),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// NOTIFICATION INTÉGRÉE (Contextuelle)
if (isOverheating)
_buildCyberAlertBanner("ALERTE THERMIQUE MATÉRIELLE", "La température du CPU principal dépasse le seuil critique (75°C). Risque de Thermal Throttling imminent.", AlertSeverity.critical)
else if (_isVastAiActive)
_buildCyberAlertBanner("AIOps ACTIF", "L'analyse prédictive est déléguée à l'instance Cloud Vast.ai.", AlertSeverity.info),

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
Expanded(flex: isMobile ? 0 : 1, child: _buildGauge("Température", _tempCelsius, "°C", isOverheating ? const Color(0xFFFF2A55) : Colors.orangeAccent)),
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
activeColor: const Color(0xFF8B5CF6),
onChanged: (val) => setState(() => _isVastAiActive = val)
),
],
),
const SizedBox(height: 12),
Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(color: const Color(0xFF131C2D), borderRadius: BorderRadius.circular(16), border: Border.all(color: _isVastAiActive ? const Color(0xFF8B5CF6) : Colors.white10)),
child: Text(_isVastAiActive ? "Délégation Cloud Active : Analyse des logs par IA en cours." : "AIOps désactivé. Analyse matérielle locale uniquement.", style: TextStyle(color: Colors.blueGrey[300], fontSize: 12)),
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
Text("${value.toInt()}$unit", style: GoogleFonts.jetbrainsMono(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
bool hasUnstableConfig = _backups.any((b) => !b.isStable);

return ListView.builder(
physics: const BouncingScrollPhysics(),
padding: const EdgeInsets.all(24),
itemCount: _backups.length + 1,
itemBuilder: (context, index) {
if (index == 0) {
return Column(
children: [
// NOTIFICATION INTÉGRÉE
if (hasUnstableConfig)
_buildCyberAlertBanner("DÉRIVE DE CONFIGURATION", "Le dernier Snapshot (v2.4.1) est marqué comme instable. Un Rollback est fortement recommandé.", AlertSeverity.warning),

Padding(
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
),
],
);
}
final backup = _backups[index - 1];
return Container(
margin: const EdgeInsets.only(bottom: 12),
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: const Color(0xFF131C2D),
borderRadius: BorderRadius.circular(16),
border: Border.all(color: !backup.isStable ? Colors.orangeAccent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05))
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Icon(backup.isStable ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.exclamationmark_circle_fill, color: backup.isStable ? Colors.greenAccent : Colors.orangeAccent, size: 20),
const SizedBox(width: 12),
Text(backup.id, style: GoogleFonts.jetbrainsMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2A55).withValues(alpha: 0.2), foregroundColor: const Color(0xFFFF2A55), minimumSize: const Size(0, 32), elevation: 0),
icon: const Icon(CupertinoIcons.arrow_counterclockwise, size: 14), label: const Text("Rollback", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
onPressed: () => _executeRollback(backup),
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
physics: const BouncingScrollPhysics(),
padding: const EdgeInsets.all(24),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// NOTIFICATION INTÉGRÉE
if (_diagnosticAlert != null)
_buildCyberAlertBanner("RÉSULTAT DU DIAGNOSTIC", _diagnosticAlert!, AlertSeverity.warning)
else if (!_isRunningDiagnostics && _diagnosticAlert == null)
_buildCyberAlertBanner("PRÊT POUR L'AUDIT", "Le moteur de diagnostic Deep-Dive est prêt à analyser les paquets.", AlertSeverity.info),

Container(
padding: const EdgeInsets.all(24),
decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF131C2D), Color(0xFF070B14)]), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3))),
child: Column(
children: [
const Icon(CupertinoIcons.waveform_path_ecg, color: Color(0xFF00E5FF), size: 40),
const SizedBox(height: 16),