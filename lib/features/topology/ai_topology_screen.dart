import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// MODÈLES
// ============================================================

enum NodeType { router, server, pc, mobile, iot }

enum AlertLevel { info, warning, critical }

class TopologyNode {
  final String id;
  final String ip;
  final NodeType type;

  /// Score de démonstration, non produit par un modèle IA réel.
  double demonstrationRiskScore;

  String statusMessage;

  Offset position = Offset.zero;

  final int cpuUsage;
  final double packetLoss;

  TopologyNode(
      this.id,
      this.ip,
      this.type,
      this.demonstrationRiskScore,
      this.statusMessage, {
        this.cpuUsage = 10,
        this.packetLoss = 0.0,
      });
}

class TopologyEdge {
  final TopologyNode source;
  final TopologyNode target;
  final double trafficPhase;

  TopologyEdge(this.source, this.target, this.trafficPhase);
}

class ActionRecord {
  final String id;
  final DateTime timestamp;
  final String targetNode;
  final String observedStatus;
  final String requestedAction;

  ActionRecord({
    required this.id,
    required this.timestamp,
    required this.targetNode,
    required this.observedStatus,
    required this.requestedAction,
  });
}

// ============================================================
// ÉCRAN
// ============================================================

class AITopologyScreen extends StatefulWidget {
  const AITopologyScreen({super.key});

  @override
  State<AITopologyScreen> createState() =>
      _AITopologyScreenState();
}

class _AITopologyScreenState extends State<AITopologyScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _trafficController;
  late final AnimationController _pulseController;

  late List<TopologyNode> _nodes;
  late List<TopologyEdge> _edges;

  TopologyNode? _selectedNode;
  bool _isSimulatingAction = false;

  final List<ActionRecord> _actionRecords = [];

  static const Color _background = Color(0xFF070B14);
  static const Color _panel = Color(0xFF131C2D);
  static const Color _accent = Color(0xFF00E5FF);
  static const Color _danger = Color(0xFFFF2A55);

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _trafficController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _initializeDemonstrationGraph();
  }

  @override
  void dispose() {
    _trafficController.dispose();
    _pulseController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeDemonstrationGraph() {
    final random = Random(7);

    final router = TopologyNode(
      'Gateway-Core',
      '192.168.1.1',
      NodeType.router,
      0.02,
      'État de démonstration : trafic nominal.',
      cpuUsage: 34,
    );

    _nodes = [router];

    final devices = [
      TopologyNode(
        'Serveur NAS',
        '192.168.1.10',
        NodeType.server,
        0.10,
        'État de démonstration : sauvegarde en cours.',
        cpuUsage: 65,
      ),
      TopologyNode(
        'PC-Dev-01',
        '192.168.1.24',
        NodeType.pc,
        0.00,
        'État de démonstration : inactif.',
        cpuUsage: 12,
      ),
      TopologyNode(
        'Mobile-01',
        '192.168.1.45',
        NodeType.mobile,
        0.92,
        'Scénario de démonstration : trafic élevé simulé. '
            'Aucune exfiltration réelle n’est détectée.',
        cpuUsage: 98,
        packetLoss: 12.5,
      ),
      TopologyNode(
        'Caméra-01',
        '192.168.1.102',
        NodeType.iot,
        0.40,
        'État de démonstration : flux instable simulé.',
      ),
      TopologyNode(
        'Smart-TV',
        '192.168.1.130',
        NodeType.iot,
        0.10,
        'État de démonstration : en veille.',
      ),
      TopologyNode(
        'PC-02',
        '192.168.1.55',
        NodeType.pc,
        0.85,
        'Scénario de démonstration : saturation simulée.',
        cpuUsage: 88,
        packetLoss: 4.2,
      ),
      TopologyNode(
        'PC-03',
        '192.168.1.60',
        NodeType.pc,
        0.20,
        'État de démonstration : navigation web.',
      ),
    ];

    _nodes.addAll(devices);
    _edges = [];

    final radius = max(180.0, devices.length * 35.0);
    final angleStep = (2 * pi) / devices.length;

    router.position = Offset.zero;

    for (int i = 0; i < devices.length; i++) {
      final angle = i * angleStep;

      devices[i].position = Offset(
        radius * cos(angle),
        radius * sin(angle),
      );

      _edges.add(
        TopologyEdge(
          router,
          devices[i],
          random.nextDouble(),
        ),
      );
    }
  }

  void _handleNodeTap(
      Offset localPosition,
      Size canvasSize,
      ) {
    if (_isSimulatingAction) return;

    final translated = localPosition -
        Offset(
          canvasSize.width / 2,
          canvasSize.height / 2,
        );

    for (final node in _nodes) {
      if ((node.position - translated).distance <= 35) {
        setState(() {
          _selectedNode = node;
        });
        return;
      }
    }
  }

  // ============================================================
  // ACTION SIMULÉE
  // ============================================================

  Future<void> _requestSimulatedAction(
      TopologyNode node,
      String actionLabel,
      ) async {
    if (_isSimulatingAction) return;

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer l’action simulée'),
        content: Text(
          'Cible : ${node.id} (${node.ip})\n'
              'Action : $actionLabel\n\n'
              'Cette démonstration ne modifie aucun équipement, '
              'aucun pare-feu et aucun agent de sécurité.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simuler'),
          ),
        ],
      ),
    );

    if (approved != true || !mounted) return;

    setState(() {
      _isSimulatingAction = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _actionRecords.insert(
        0,
        ActionRecord(
          id: 'SIM-${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          targetNode: node.id,
          observedStatus: node.statusMessage,
          requestedAction: actionLabel,
        ),
      );

      node.demonstrationRiskScore = 0.05;
      node.statusMessage =
      'Action simulée : « $actionLabel ». '
          'Aucun équipement réel n’a été modifié.';

      _selectedNode = null;
      _isSimulatingAction = false;
    });

    _notify(
      'Action simulée enregistrée pour ${node.ip}. '
          'Aucune modification réseau réelle.',
    );
  }

  void _notify(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ============================================================
  // INTERFACE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: const Text(
          'Topologie de démonstration',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _accent,
          labelColor: _accent,
          unselectedLabelColor: Colors.blueGrey,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(
              icon: Icon(CupertinoIcons.map_pin_ellipse,
                  size: 18),
              text: 'Carte',
            ),
            Tab(
              icon: Icon(CupertinoIcons.doc_text_fill,
                  size: 18),
              text: 'Actions simulées',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildTopologyView(),
            _buildRecordsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBanner() {
    final critical = _nodes
        .where((node) => node.demonstrationRiskScore > 0.8)
        .length;

    final warning = _nodes
        .where(
          (node) =>
      node.demonstrationRiskScore > 0.5 &&
          node.demonstrationRiskScore <= 0.8,
    )
        .length;

    if (critical == 0 && warning == 0) {
      return const SizedBox.shrink();
    }

    final isCritical = critical > 0;
    final color =
    isCritical ? _danger : Colors.orangeAccent;

    final message = isCritical
        ? '$critical nœud(s) de démonstration présentent '
        'un score élevé. Il ne s’agit pas d’une détection '
        'réelle.'
        : '$warning nœud(s) de démonstration présentent '
        'un score intermédiaire.';

    final content = Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCritical
                ? CupertinoIcons.exclamationmark_triangle_fill
                : CupertinoIcons.exclamationmark_shield_fill,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCritical
                      ? 'SCORE ÉLEVÉ — DÉMONSTRATION'
                      : 'SCORE INTERMÉDIAIRE — DÉMONSTRATION',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!isCritical) return content;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => Transform.scale(
        scale: 1 + (_pulseController.value * 0.02),
        child: child,
      ),
      child: content,
    );
  }

  Widget _buildTopologyView() {
    const canvasSize = Size(1800, 1800);

    return Stack(
      children: [
        InteractiveViewer(
          minScale: 0.4,
          maxScale: 3,
          boundaryMargin: const EdgeInsets.all(800),
          constrained: false,
          child: GestureDetector(
            onTapUp: (details) => _handleNodeTap(
              details.localPosition,
              canvasSize,
            ),
            child: SizedBox(
              width: canvasSize.width,
              height: canvasSize.height,
              child: AnimatedBuilder(
                animation: _trafficController,
                builder: (context, child) => CustomPaint(
                  painter: NetworkTopologyPainter(
                    _nodes,
                    _edges,
                    _trafficController.value,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Column(
            children: [
              _buildRiskBanner(),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(
                    right: 24,
                    top: 8,
                  ),
                  child: IconButton(
                    tooltip:
                    'Désélectionner le nœud affiché',
                    onPressed: () {
                      setState(() {
                        _selectedNode = null;
                      });
                    },
                    icon: const Icon(
                      CupertinoIcons.viewfinder,
                      color: _accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_selectedNode != null)
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _buildNodePanel(),
          ),
      ],
    );
  }

  Widget _buildNodePanel() {
    final node = _selectedNode!;
    final isCritical =
        node.demonstrationRiskScore > 0.8;
    final color = isCritical ? _danger : _accent;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15,
          sigmaY: 15,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _panel.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: color.withValues(alpha: 0.5),
            ),
          ),
          child: _isSimulatingAction
              ? const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Simulation en cours. '
                    'Aucun équipement n’est contacté.',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          )
              : Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.id,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          node.ip,
                          style: GoogleFonts
                              .jetBrainsMono(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedNode = null;
                      });
                    },
                    icon: const Icon(
                      CupertinoIcons.clear_circled,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white12),
              const Text(
                'ÉTAT DE DÉMONSTRATION',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                node.statusMessage,
                style: TextStyle(
                  color: isCritical
                      ? _danger
                      : Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceAround,
                children: [
                  _metric(
                    'Score de démonstration',
                    '${(node.demonstrationRiskScore * 100).round()}%',
                    color,
                  ),
                  _metric(
                    'CPU simulé',
                    '${node.cpuUsage}%',
                    node.cpuUsage > 80
                        ? Colors.orangeAccent
                        : _accent,
                  ),
                  _metric(
                    'Perte simulée',
                    '${node.packetLoss}%',
                    node.packetLoss > 5
                        ? _danger
                        : _accent,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'ACTIONS SIMULÉES',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                childAspectRatio: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                physics:
                const NeverScrollableScrollPhysics(),
                children: [
                  _actionButton(
                    'Isolation simulée',
                    CupertinoIcons.shield_lefthalf_fill,
                    _danger,
                        () => _requestSimulatedAction(
                      node,
                      'Isolation simulée',
                    ),
                  ),
                  _actionButton(
                    'Inspection simulée',
                    CupertinoIcons.waveform_path_ecg,
                    Colors.orangeAccent,
                        () => _requestSimulatedAction(
                      node,
                      'Inspection approfondie simulée',
                    ),
                  ),
                  _actionButton(
                    'Limitation simulée',
                    CupertinoIcons.speedometer,
                    Colors.purpleAccent,
                        () => _requestSimulatedAction(
                      node,
                      'Limitation de débit simulée',
                    ),
                  ),
                  _actionButton(
                    'Vérification simulée',
                    CupertinoIcons.ant,
                    _accent,
                        () => _requestSimulatedAction(
                      node,
                      'Vérification endpoint simulée',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton(
      String label,
      IconData icon,
      Color color,
      VoidCallback onPressed,
      ) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: color.withValues(alpha: 0.5),
        ),
        alignment: Alignment.centerLeft,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _metric(
      String label,
      String value,
      Color color,
      ) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Registre des actions simulées',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: _actionRecords.isEmpty
                    ? null
                    : () {
                  setState(() {
                    _actionRecords.clear();
                  });
                },
                child: const Text('Vider le registre'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _actionRecords.isEmpty
              ? const Center(
            child: Text(
              'Aucune action simulée pour le moment.',
              style: TextStyle(color: Colors.white38),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
            ),
            itemCount: _actionRecords.length,
            itemBuilder: (context, index) {
              final record = _actionRecords[index];

              return Container(
                margin:
                const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _panel,
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                      children: [
                        Text(
                          record.id,
                          style: GoogleFonts
                              .jetBrainsMono(
                            color: _accent,
                            fontSize: 12,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        Text(
                          record.timestamp
                              .toLocal()
                              .toString(),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cible : ${record.targetNode}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'État observé : '
                          '${record.observedStatus}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent
                            .withValues(alpha: 0.1),
                        borderRadius:
                        BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Action simulée demandée : '
                            '${record.requestedAction}',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================
// DESSIN DE LA TOPOLOGIE
// ============================================================

class NetworkTopologyPainter extends CustomPainter {
  final List<TopologyNode> nodes;
  final List<TopologyEdge> edges;
  final double animationValue;

  NetworkTopologyPainter(
      this.nodes,
      this.edges,
      this.animationValue,
      );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);

    for (final edge in edges) {
      final risk =
          edge.target.demonstrationRiskScore;

      final Color lineColor;

      if (risk > 0.8) {
        lineColor = const Color(0xFFFF2A55);
      } else if (risk > 0.5) {
        lineColor = Colors.orangeAccent;
      } else {
        lineColor = const Color(0xFF00E5FF);
      }

      final linePaint = Paint()
        ..color = lineColor.withValues(alpha: 0.3)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        edge.source.position,
        edge.target.position,
        linePaint,
      );

      final progress =
          (animationValue + edge.trafficPhase) % 1;

      final packetPosition = Offset(
        edge.source.position.dx +
            (edge.target.position.dx -
                edge.source.position.dx) *
                progress,
        edge.source.position.dy +
            (edge.target.position.dy -
                edge.source.position.dy) *
                progress,
      );

      canvas.drawCircle(
        packetPosition,
        3.5,
        Paint()
          ..color = lineColor
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            4,
          ),
      );
    }

    for (final node in nodes) {
      final risk = node.demonstrationRiskScore;

      Color nodeColor = const Color(0xFF00E5FF);

      if (risk > 0.8) {
        nodeColor = const Color(0xFFFF2A55);
      } else if (risk > 0.5) {
        nodeColor = Colors.orangeAccent;
      }

      final radius =
      node.type == NodeType.router ? 32.0 : 22.0;

      canvas.drawCircle(
        node.position,
        radius + 8,
        Paint()
          ..color = nodeColor.withValues(alpha: 0.25)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            risk > 0.5 ? 16 : 8,
          ),
      );

      canvas.drawCircle(
        node.position,
        radius,
        Paint()..color = const Color(0xFF131C2D),
      );

      canvas.drawCircle(
        node.position,
        radius,
        Paint()
          ..color = nodeColor
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );

      final icon = switch (node.type) {
        NodeType.router => CupertinoIcons.rocket_fill,
        NodeType.server => Icons.dns,
        NodeType.mobile =>
        CupertinoIcons.device_phone_portrait,
        NodeType.iot => CupertinoIcons.video_camera,
        NodeType.pc => CupertinoIcons.device_desktop,
      };

      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: radius * 0.8,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      iconPainter.layout();

      iconPainter.paint(
        canvas,
        Offset(
          node.position.dx - iconPainter.width / 2,
          node.position.dy - iconPainter.height / 2,
        ),
      );

      final labelPainter = TextPainter(
        text: TextSpan(
          text: '${node.id}\n${node.ip}',
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white70,
            fontSize: 10,
            height: 1.2,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      labelPainter.layout();

      labelPainter.paint(
        canvas,
        Offset(
          node.position.dx - labelPainter.width / 2,
          node.position.dy + radius + 8,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(
      covariant NetworkTopologyPainter oldDelegate,
      ) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.nodes != nodes ||
        oldDelegate.edges != edges;
  }
}