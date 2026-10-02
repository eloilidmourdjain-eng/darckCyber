import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

// ==========================================
// MODÈLES DE DONNÉES (Graphe & AIOps)
// ==========================================
enum NodeType { router, server, pc, mobile, iot }
enum AlertSeverity { info, warning, critical }

class TopologyNode {
  final String id;
  final String ip;
  final NodeType type;
  double aiAnomalyScore; // 0.0 à 1.0
  String statusMessage;
  Offset position = Offset.zero;

  // Métriques simulées
  final int cpuUsage;
  final double packetLoss;

  TopologyNode(this.id, this.ip, this.type, this.aiAnomalyScore, this.statusMessage, {this.cpuUsage = 10, this.packetLoss = 0.0});
}

class TopologyEdge {
  final TopologyNode source;
  final TopologyNode target;
  final double bandwidthUsage;
  TopologyEdge(this.source, this.target, this.bandwidthUsage);
}

class IncidentReport {
  final String id;
  final String timestamp;
  final String targetNode;
  final String issue;
  final String actionTaken;

  IncidentReport(this.id, this.timestamp, this.targetNode, this.issue, this.actionTaken);
}

// ==========================================
// FENÊTRE PRINCIPALE
// ==========================================
class AITopologyScreen extends StatefulWidget {
  const AITopologyScreen({super.key});

  @override
  State<AITopologyScreen> createState() => _AITopologyScreenState();
}

class _AITopologyScreenState extends State<AITopologyScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _trafficController;
  late AnimationController _pulseController;

  late List<TopologyNode> _nodes;
  late List<TopologyEdge> _edges;

  TopologyNode? _selectedNode;
  bool _isRemediating = false; // Statut de traitement SOAR
  final List<IncidentReport> _generatedReports = [];

  // Thème
  final Color kBgColor = const Color(0xFF070B14);
  final Color kPanelColor = const Color(0xFF131C2D);
  final Color kCyan = const Color(0xFF00E5FF);
  final Color kRed = const Color(0xFFFF2A55);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _trafficController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _initializeNetworkGraph();
  }

  @override
  void dispose() {
    _trafficController.dispose();
    _pulseController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeNetworkGraph() {
    TopologyNode router = TopologyNode("Gateway-Core", "192.168.1.1", NodeType.router, 0.02, "Trafic Nominal", cpuUsage: 34);
    _nodes = [router];

    List<TopologyNode> devices = [
      TopologyNode("Serveur NAS", "192.168.1.10", NodeType.server, 0.1, "Sauvegarde en cours", cpuUsage: 65),
      TopologyNode("PC-Dev-01", "192.168.1.24", NodeType.pc, 0.0, "Idle", cpuUsage: 12),
      TopologyNode("iPhone-CEO", "192.168.1.45", NodeType.mobile, 0.92, "Anomalie : Exfiltration de données suspectée (Trafic UDP massif)", cpuUsage: 98, packetLoss: 12.5),
      TopologyNode("Caméra-Ext", "192.168.1.102", NodeType.iot, 0.4, "Flux vidéo instable"),
      TopologyNode("Smart-TV", "192.168.1.130", NodeType.iot, 0.1, "En veille"),
      TopologyNode("PC-Compta", "192.168.1.55", NodeType.pc, 0.85, "Goulot d'étranglement : Bande passante saturée (Torrent détecté)", cpuUsage: 88, packetLoss: 4.2),
      TopologyNode("MacBook-Air", "192.168.1.60", NodeType.pc, 0.2, "Navigation Web"),
    ];
    _nodes.addAll(devices);
    _edges = [];

    double dynamicRadius = max(180.0, devices.length * 35.0);
    double angleStep = (2 * pi) / devices.length;

    router.position = const Offset(0, 0);
    for (int i = 0; i < devices.length; i++) {
      double angle = i * angleStep;
      devices[i].position = Offset(dynamicRadius * cos(angle), dynamicRadius * sin(angle));
      _edges.add(TopologyEdge(router, devices[i], Random().nextDouble()));
    }
  }

  void _handleNodeTap(Offset localPosition, Size canvasCenterSize) {
    if (_isRemediating) return; // Bloque les actions pendant une résolution

    Offset translatedPos = localPosition - Offset(canvasCenterSize.width / 2, canvasCenterSize.height / 2);
    for (var node in _nodes) {
      if ((node.position - translatedPos).distance <= 35.0) {
        setState(() => _selectedNode = node);
        break;
      }
    }
  }

  // --- ACTIONS DE REMÉDIATION SOAR (Simulation Asynchrone) ---
  void _executeRemediation(String actionName) async {
    if (_selectedNode == null) return;
    final target = _selectedNode!;

    setState(() => _isRemediating = true);

    // Simulation du temps de déploiement réseau (API Firewall / Switch)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      // 1. Génération du Rapport d'Incident
      _generatedReports.insert(0, IncidentReport(
          "INC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
          "${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}",
          target.id,
          target.statusMessage,
          actionName
      ));

      // 2. Résolution visuelle du problème
      target.aiAnomalyScore = 0.05;
      target.statusMessage = "Résolu par l'opérateur ($actionName). Statut Nominal.";
      _selectedNode = null;
      _isRemediating = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.greenAccent,
      content: Row(
        children: [
          const Icon(CupertinoIcons.check_mark_circled_solid, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(child: Text("Action '$actionName' appliquée avec succès sur ${target.ip}.", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: const Text('AIOps & Topologie Prédictive', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kCyan,
          labelColor: kCyan,
          unselectedLabelColor: Colors.blueGrey[600],
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(CupertinoIcons.map_pin_ellipse, size: 18), text: "Carte Spatiale (Live)"),
            Tab(icon: Icon(CupertinoIcons.doc_text_fill, size: 18), text: "Rapports & Audit"),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildTopologyView(),
            _buildReportsTab(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SYSTÈME DE NOTIFICATION INTÉGRÉ
  // ==========================================
  Widget _buildCyberAlertBanner() {
    int criticalNodes = _nodes.where((n) => n.aiAnomalyScore > 0.8).length;
    int warningNodes = _nodes.where((n) => n.aiAnomalyScore > 0.5 && n.aiAnomalyScore <= 0.8).length;

    if (criticalNodes == 0 && warningNodes == 0) {
      return const SizedBox.shrink(); // Tout va bien, on cache la bannière
    }

    bool isCritical = criticalNodes > 0;
    Color accentColor = isCritical ? kRed : Colors.orangeAccent;
    IconData icon = isCritical ? CupertinoIcons.exclamationmark_triangle_fill : CupertinoIcons.exclamationmark_shield_fill;
    String title = isCritical ? "MENACE CRITIQUE DÉTECTÉE" : "AVERTISSEMENT RÉSEAU";
    String message = isCritical
        ? "L'IA a détecté $criticalNodes nœud(s) avec un comportement malveillant (Exfiltration/Surcharge). Action immédiate requise."
        : "$warningNodes nœud(s) présentent une dégradation de performance.";

    Widget alertContent = Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131C2D),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
        boxShadow: isCritical ? [BoxShadow(color: accentColor.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: -2)] : [],
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
        ],
      ),
    );

    return isCritical ? AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) => Transform.scale(scale: 1.0 + (_pulseController.value * 0.02), child: alertContent)
    ) : alertContent;
  }

  // ==========================================
  // ONGLET 1 : TOPOLOGIE ET PANNEAU D'ACTION
  // ==========================================
  Widget _buildTopologyView() {
    const Size canvasSize = Size(1800, 1800);

    return Stack(
      children: [
        // MOTEUR DE RENDU INTERACTIF
        InteractiveViewer(
          minScale: 0.4, maxScale: 3.0,
          boundaryMargin: const EdgeInsets.all(800),
          constrained: false,
          child: GestureDetector(
            onTapUp: (details) => _handleNodeTap(details.localPosition, canvasSize),
            child: SizedBox(
              width: canvasSize.width, height: canvasSize.height,
              child: AnimatedBuilder(
                animation: _trafficController,
                builder: (context, child) => CustomPaint(painter: NetworkTopologyPainter(_nodes, _edges, _trafficController.value)),
              ),
            ),
          ),
        ),

        // NOTIFICATION BANNER TOP
        Positioned(
          top: 0, left: 0, right: 0,
          child: Column(
            children: [
              _buildCyberAlertBanner(),
              // Bouton Recenter
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 24, top: 8),
                  child: Container(
                    decoration: BoxDecoration(color: kPanelColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                    child: IconButton(icon: Icon(CupertinoIcons.viewfinder, color: kCyan), tooltip: "Recentrer la vue", onPressed: () => setState(() => _selectedNode = null)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // PANNEAU D'INTERVENTION MODAL (Drill-Down)
        if (_selectedNode != null)
          Positioned(
            bottom: 24, left: 24, right: 24,
            child: _buildRemediationModal(),
          ),
      ],
    );
  }

  // LE PANNEAU DE REMÉDIATION (SOAR TOOLKIT)
  Widget _buildRemediationModal() {
    final node = _selectedNode!;
    final isCritical = node.aiAnomalyScore > 0.8;
    final color = isCritical ? kRed : kCyan;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kPanelColor.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: _isRemediating
              ? _buildRemediationProgress() // État de chargement
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- HEADER MODAL ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(CupertinoIcons.device_laptop, color: color, size: 24)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(node.id, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          Text(node.ip, style: GoogleFonts.jetBrainsMono(color: Colors.blueGrey[300], fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(icon: const Icon(CupertinoIcons.clear_circled_solid, color: Colors.blueGrey), onPressed: () => setState(() => _selectedNode = null))
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white12, height: 1)),

              // --- ANALYSE IA (RCA) ---
              const Text("ROOT CAUSE ANALYSIS (IA)", style: TextStyle(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text(node.statusMessage, style: TextStyle(color: isCritical ? kRed : Colors.white70, fontSize: 13, fontWeight: isCritical ? FontWeight.bold : FontWeight.normal)),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniMetric("Score IA", "${(node.aiAnomalyScore * 100).toInt()}%", color),
                  _buildMiniMetric("CPU Usage", "${node.cpuUsage}%", node.cpuUsage > 80 ? Colors.orangeAccent : kCyan),
                  _buildMiniMetric("Packet Loss", "${node.packetLoss}%", node.packetLoss > 5.0 ? kRed : kCyan),
                ],
              ),
              const SizedBox(height: 24),

              // --- ARSENAL DE REMÉDIATION (SOAR) ---
              const Text("OUTILS DE RÉSOLUTION (SOAR PLAYBOOKS)", style: TextStyle(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                childAspectRatio: 3.0,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildActionBtn("Micro-Segmentation (Zero Trust)", CupertinoIcons.shield_lefthalf_fill, kRed, "Isolation VLAN L2"),
                  _buildActionBtn("Activer Deep Packet Inspection", CupertinoIcons.waveform_path_ecg, Colors.orangeAccent, "Routage vers IA"),
                  _buildActionBtn("Throttling (QoS 1Mbps)", CupertinoIcons.speedometer, Colors.purpleAccent, "Brider Bande Passante"),
                  _buildActionBtn("Trigger EDR Agent (Kill Process)", CupertinoIcons.ant_fill, kCyan, "Nettoyage Endpoint"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Barre de progression pendant l'exécution de l'action
  Widget _buildRemediationProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          const CircularProgressIndicator(color: Color(0xFF00E5FF)),
          const SizedBox(height: 20),
          Text("Injection des règles réseaux (API Controller)...", style: GoogleFonts.jetBrainsMono(color: const Color(0xFF00E5FF), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, String actionId) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.centerLeft,
      ),
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
      onPressed: () => _executeRemediation(actionId),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.jetBrainsMono(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.blueGrey[400], fontSize: 10)),
      ],
    );
  }

  // ==========================================
  // ONGLET 2 : RAPPORTS ET AUDIT
  // ==========================================
  Widget _buildReportsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Registres de Remédiation IA", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: kPanelColor, foregroundColor: kCyan, side: BorderSide(color: kCyan.withValues(alpha: 0.5))),
                icon: const Icon(CupertinoIcons.cloud_download, size: 16),
                label: const Text("Exporter (PDF)"),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Le rapport PDF a été généré et téléchargé avec succès.")));
                },
              )
            ],
          ),
        ),
        Expanded(
          child: _generatedReports.isEmpty
              ? Center(child: Text("Aucun incident résolu pour le moment.", style: TextStyle(color: Colors.blueGrey[600])))
              : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _generatedReports.length,
            itemBuilder: (context, index) {
              final report = _generatedReports[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kPanelColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(report.id, style: GoogleFonts.jetBrainsMono(color: kCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(report.timestamp, style: GoogleFonts.jetBrainsMono(color: Colors.blueGrey[500], fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("Cible: ${report.targetNode}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Cause IA: ${report.issue}", style: TextStyle(color: Colors.blueGrey[300], fontSize: 11)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.check_mark_circled_solid, color: Colors.greenAccent, size: 14),
                          const SizedBox(width: 8),
                          Expanded(child: Text("Playbook Exécuté: ${report.actionTaken}", style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    )
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

// ==========================================
// MOTEUR GRAPHIQUE (Optimisé Flutter 3.24)
// ==========================================
class NetworkTopologyPainter extends CustomPainter {
  final List<TopologyNode> nodes;
  final List<TopologyEdge> edges;
  final double animationValue;

  NetworkTopologyPainter(this.nodes, this.edges, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);

    for (var edge in edges) {
      bool isCritical = edge.target.aiAnomalyScore > 0.8;
      bool isWarning = edge.target.aiAnomalyScore > 0.5 && edge.target.aiAnomalyScore <= 0.8;

      Color lineColor = isCritical ? const Color(0xFFFF2A55) : (isWarning ? Colors.orangeAccent : const Color(0xFF00E5FF));

      final paintLine = Paint()
        ..color = lineColor.withValues(alpha: 0.3)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(edge.source.position, edge.target.position, paintLine);

      double progress = (animationValue + edge.bandwidthUsage) % 1.0;
      double packetX = edge.source.position.dx + (edge.target.position.dx - edge.source.position.dx) * progress;
      double packetY = edge.source.position.dy + (edge.target.position.dy - edge.source.position.dy) * progress;

      final paintPacket = Paint()
        ..color = lineColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawCircle(Offset(packetX, packetY), 3.5, paintPacket);
    }

    for (var node in nodes) {
      Color nodeColor = const Color(0xFF00E5FF);
      if (node.aiAnomalyScore > 0.8) nodeColor = const Color(0xFFFF2A55);
      else if (node.aiAnomalyScore > 0.5) nodeColor = Colors.orangeAccent;

      double nodeRadius = node.type == NodeType.router ? 32.0 : 22.0;

      final paintGlow = Paint()
        ..color = nodeColor.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, node.aiAnomalyScore > 0.5 ? 16.0 : 8.0);
      canvas.drawCircle(node.position, nodeRadius + 8, paintGlow);

      final paintNode = Paint()..color = const Color(0xFF131C2D);
      final paintBorder = Paint()
        ..color = nodeColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(node.position, nodeRadius, paintNode);
      canvas.drawCircle(node.position, nodeRadius, paintBorder);

      IconData icon;
      switch (node.type) {
        case NodeType.router: icon = CupertinoIcons.rocket_fill; break;
        case NodeType.server: icon = Icons.dns; break;
        case NodeType.mobile: icon = CupertinoIcons.device_phone_portrait; break;
        case NodeType.iot: icon = CupertinoIcons.video_camera; break;
        case NodeType.pc: default: icon = CupertinoIcons.device_desktop; break;
      }

      TextPainter textPainter = TextPainter(
        text: TextSpan(text: String.fromCharCode(icon.codePoint), style: TextStyle(fontSize: nodeRadius * 0.8, fontFamily: icon.fontFamily, package: icon.fontPackage, color: Colors.white)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(node.position.dx - (textPainter.width / 2), node.position.dy - (textPainter.height / 2)));

      TextPainter labelPainter = TextPainter(
        text: TextSpan(
          text: "${node.id}\n${node.ip}",
          style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 10, height: 1.2),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(node.position.dx - (labelPainter.width / 2), node.position.dy + nodeRadius + 8));
    }
  }

  @override
  bool shouldRepaint(covariant NetworkTopologyPainter oldDelegate) => oldDelegate.animationValue != animationValue;
}