import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

// --- MODÈLES DE DONNÉES (Graphe & AIOps) ---
enum NodeType { router, server, pc, mobile, iot }

class TopologyNode {
  final String id;
  final String ip;
  final NodeType type;
  final double aiAnomalyScore; // Score IA: 0.0 (Sain) à 1.0 (Critique)
  Offset position = Offset.zero;

  TopologyNode(this.id, this.ip, this.type, this.aiAnomalyScore);
}

class TopologyEdge {
  final TopologyNode source;
  final TopologyNode target;
  final double bandwidthUsage;
  TopologyEdge(this.source, this.target, this.bandwidthUsage);
}

// --- FENÊTRE PRINCIPALE ---
class AITopologyScreen extends StatefulWidget {
  const AITopologyScreen({Key? key}) : super(key: key);

  @override
  _AITopologyScreenState createState() => _AITopologyScreenState();
}

class _AITopologyScreenState extends State<AITopologyScreen> with SingleTickerProviderStateMixin {
  late List<TopologyNode> _nodes;
  late List<TopologyEdge> _edges;
  late AnimationController _trafficController;

  TopologyNode? _selectedNode; // Gestion de l'interaction tactile

  @override
  void initState() {
    super.initState();
    _initializeNetworkGraph();
    // Animation optimisée à 60 FPS pour les paquets réseau
    _trafficController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _trafficController.dispose();
    super.dispose();
  }

  // --- L'ALGORITHME DE GÉNÉRATION DYNAMIQUE (Anti-Collision) ---
  void _initializeNetworkGraph() {
    TopologyNode router = TopologyNode("Gateway", "192.168.1.1", NodeType.router, 0.05);
    _nodes = [router];

    List<TopologyNode> devices = [
      TopologyNode("Serveur NAS", "192.168.1.10", NodeType.server, 0.1),
      TopologyNode("PC-Dev-01", "192.168.1.24", NodeType.pc, 0.0),
      TopologyNode("iPhone-CEO", "192.168.1.45", NodeType.mobile, 0.85), // Anomalie IA
      TopologyNode("Caméra-Ext", "192.168.1.102", NodeType.iot, 0.4),
      TopologyNode("Smart-TV", "192.168.1.130", NodeType.iot, 0.1),
      TopologyNode("PC-Compta", "192.168.1.55", NodeType.pc, 0.95), // Goulot d'étranglement
      TopologyNode("MacBook-Air", "192.168.1.60", NodeType.pc, 0.2),
    ];
    _nodes.addAll(devices);
    _edges = [];

    // ALGORITHME AMÉLIORÉ : Rayon adaptatif en fonction de la volumétrie des nœuds (Anti-Collision)
    double dynamicRadius = max(180.0, devices.length * 28.0);
    double angleStep = (2 * pi) / devices.length;

    router.position = const Offset(0, 0);
    for (int i = 0; i < devices.length; i++) {
      double angle = i * angleStep;
      double dx = dynamicRadius * cos(angle);
      double dy = dynamicRadius * sin(angle);
      devices[i].position = Offset(dx, dy);
      _edges.add(TopologyEdge(router, devices[i], Random().nextDouble()));
    }
  }

  // Détection du nœud touché par l'utilisateur
  void _handleNodeTap(Offset localPosition, Size canvasCenterSize) {
    Offset translatedPos = localPosition - Offset(canvasCenterSize.width / 2, canvasCenterSize.height / 2);

    for (var node in _nodes) {
      double distance = (node.position - translatedPos).distance;
      if (distance <= 30.0) { // Rayon de tolérance tactile
        setState(() {
          _selectedNode = node;
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Size canvasSize = Size(1800, 1800);

    return Scaffold(
      backgroundColor: const Color(0xFF070B19),
      body: SafeArea(
        child: Stack(
          children: [
            // --- 1. MOTEUR DE RENDU INTERACTIF ---
            InteractiveViewer(
              minScale: 0.4,
              maxScale: 3.0,
              boundaryMargin: const EdgeInsets.all(600),
              constrained: false,
              child: GestureDetector(
                onTapUp: (details) => _handleNodeTap(details.localPosition, canvasSize),
                child: SizedBox(
                  width: canvasSize.width,
                  height: canvasSize.height,
                  child: AnimatedBuilder(
                    animation: _trafficController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: NetworkTopologyPainter(_nodes, _edges, _trafficController.value),
                      );
                    },
                  ),
                ),
              ),
            ),

            // --- 2. OVERLAY UI (Panneau IA & Alertes) ---
            Positioned(
              top: 24,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AIOps Topology (Secure)', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      _buildAIStatusBadge(),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                    child: IconButton(
                      icon: const Icon(CupertinoIcons.viewfinder, color: Colors.cyanAccent),
                      onPressed: () {
                        setState(() => _selectedNode = null);
                      },
                    ),
                  )
                ],
              ),
            ),

            // --- 3. PANNEAU DE CONTRÔLE / INSPECTION DE NŒUD SÉLECTIONNÉ ---
            if (_selectedNode != null)
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _selectedNode!.aiAnomalyScore > 0.8 ? Colors.redAccent : Colors.cyanAccent),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Appareil : ${_selectedNode!.id}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text("IP : ${_selectedNode!.ip} | Risque IA : ${(_selectedNode!.aiAnomalyScore * 100).toInt()}%", style: GoogleFonts.jetBrainsMono(color: Colors.blueGrey[300], fontSize: 12)),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () {
                          setState(() {
                            // Simulation d'une action de remédiation ciblée (Quarantaine SDN)
                            _nodes.remove(_selectedNode);
                            _selectedNode = null;
                          });
                        },
                        child: const Text("Mettre en Quarantaine", style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.sparkles, color: Colors.redAccent, size: 16),
          SizedBox(width: 8),
          Text("2 Anomalies détectées par l'IA", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

// --- LE MOTEUR GRAPHIQUE OPTIMISÉ (CustomPainter) ---
class NetworkTopologyPainter extends CustomPainter {
  final List<TopologyNode> nodes;
  final List<TopologyEdge> edges;
  final double animationValue;

  NetworkTopologyPainter(this.nodes, this.edges, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);

    // --- 1. DESSINER LES LIENS (Câbles virtuels & Paquets) ---
    for (var edge in edges) {
      bool isCritical = edge.target.aiAnomalyScore > 0.8;

      final paintLine = Paint()
        ..color = isCritical ? Colors.redAccent.withOpacity(0.4) : Colors.cyanAccent.withOpacity(0.2)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(edge.source.position, edge.target.position, paintLine);

      double progress = (animationValue + edge.bandwidthUsage) % 1.0;
      double packetX = edge.source.position.dx + (edge.target.position.dx - edge.source.position.dx) * progress;
      double packetY = edge.source.position.dy + (edge.target.position.dy - edge.source.position.dy) * progress;

      final paintPacket = Paint()
        ..color = isCritical ? Colors.redAccent : Colors.cyanAccent
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      canvas.drawCircle(Offset(packetX, packetY), 3.5, paintPacket);
    }

    // --- 2. DESSINER LES NŒUDS ---
    for (var node in nodes) {
      Color nodeColor = Colors.cyanAccent;
      if (node.aiAnomalyScore > 0.8) nodeColor = Colors.redAccent;
      else if (node.aiAnomalyScore > 0.5) nodeColor = Colors.orangeAccent;

      double nodeRadius = node.type == NodeType.router ? 32.0 : 22.0;

      final paintGlow = Paint()
        ..color = nodeColor.withOpacity(0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, node.aiAnomalyScore > 0.8 ? 16.0 : 8.0);
      canvas.drawCircle(node.position, nodeRadius + 8, paintGlow);

      final paintNode = Paint()..color = const Color(0xFF1E293B);
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
  bool shouldRepaint(covariant NetworkTopologyPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

