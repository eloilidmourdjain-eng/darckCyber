import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:fl_chart/fl_chart.dart';

// ==========================================
// MODÈLES DE DONNÉES SÉCURISÉS
// ==========================================
enum ThreatLevel { info, warning, critical }
enum AlertSeverity { info, warning, critical }

class SecurityEvent {
  final String title;
  final String description;
  final DateTime timestamp;
  final ThreatLevel level;
  SecurityEvent(this.title, this.description, this.level) : timestamp = DateTime.now();
}

class EndpointDevice {
  final String ip;
  final String mac;
  final String os;
  bool isTrusted;
  bool isQuarantined;
  EndpointDevice(this.ip, this.mac, this.os, {this.isTrusted = true, this.isQuarantined = false});
}

// ==========================================
// FENÊTRE PRINCIPALE : IDS & SÉCURITÉ
// ==========================================
class SecurityAlertsScreen extends StatefulWidget {
  const SecurityAlertsScreen({super.key});

  @override
  State<SecurityAlertsScreen> createState() => _SecurityAlertsScreenState();
}

class _SecurityAlertsScreenState extends State<SecurityAlertsScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // --- ÉTATS IDS ---
  final List<SecurityEvent> _logs = [];
  bool _isNetworkSecured = true;
  String _activeThreatMessage = "";

  static const String _trustedGatewayMac = "00:14:22:01:23:45";
  final String _gatewayMacDisplay = "Attendue: $_trustedGatewayMac";

  // --- ÉTATS GRAPHIQUE VOLUMÉTRIQUE (DDoS / Exfiltration) ---
  final List<FlSpot> _normalTraffic = [];
  final List<FlSpot> _anomalousTraffic = [];
  double _timeCounter = 0;
  bool _isDdosAttack = false;

  // --- ÉTATS NAC (Network Access Control) ---
  final List<EndpointDevice> _endpoints = [
    EndpointDevice("192.168.1.10", "A4:5E:60:E2:11:33", "Windows Server"),
    EndpointDevice("192.168.1.45", "B8:27:EB:AA:BB:CC", "iOS (CEO)"),
    EndpointDevice("192.168.1.109", "Unkown MAC", "Espressif IoT", isTrusted: false), // Rogue Device
  ];

  Timer? _idsEngineTimer;
  Timer? _trafficTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final Color kBgColor = const Color(0xFF070B14);
  final Color kPanelColor = const Color(0xFF131C2D);
  final Color kCyan = const Color(0xFF00E5FF);
  final Color kRed = const Color(0xFFFF2A55);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _initializeEventLogs();
    _startIntrusionDetectionEngine();
    _startTrafficSimulation();
  }

  @override
  void dispose() {
    _idsEngineTimer?.cancel();
    _trafficTimer?.cancel();
    _pulseController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _initializeEventLogs() {
    _logs.add(SecurityEvent("Analyse de démarrage", "Vérification des règles pare-feu et intégrité de l'IDS (OK).", ThreatLevel.info));
    _logs.add(SecurityEvent("Mise à jour de la Whitelist", "Appareil approuvé enregistré dans le registre local.", ThreatLevel.info));

    for (int i = 0; i < 20; i++) {
      _normalTraffic.add(FlSpot(i.toDouble(), 10 + Random().nextDouble() * 10)); // Trafic de base (10-20 Mbps)
      _anomalousTraffic.add(FlSpot(i.toDouble(), 0));
    }
    _timeCounter = 19;
  }

  // --- MOTEUR IDS ---
  void _startIntrusionDetectionEngine() {
    _idsEngineTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted) return;

      // 1. Simulation ARP Spoofing
      if (timer.tick == 2) {
        _triggerAlert("Attaque ARP Spoofing !", "L'adresse MAC de la passerelle a été usurpée (MITM suspecté).", ThreatLevel.critical);
      }

      // 2. Simulation Volumétrique (DDoS)
      if (timer.tick == 4) {
        setState(() {
          _isDdosAttack = true;
          _triggerAlert("Anomalie Volumétrique", "Pic de trafic entrant détecté (DDoS SYN Flood potentiel).", ThreatLevel.warning);
        });
      }
    });
  }

  void _startTrafficSimulation() {
    _trafficTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _timeCounter++;
        _normalTraffic.removeAt(0);
        _anomalousTraffic.removeAt(0);

        double normalBase = 10 + Random().nextDouble() * 10;
        _normalTraffic.add(FlSpot(_timeCounter, normalBase));

        if (_isDdosAttack) {
          // Génère un pic énorme (jusqu'à 90 Mbps)
          _anomalousTraffic.add(FlSpot(_timeCounter, normalBase + 50 + Random().nextDouble() * 30));
        } else {
          _anomalousTraffic.add(FlSpot(_timeCounter, 0));
        }

        // Recalcule les X
        for (int i = 0; i < _normalTraffic.length; i++) {
          _normalTraffic[i] = FlSpot(i.toDouble(), _normalTraffic[i].y);
          _anomalousTraffic[i] = FlSpot(i.toDouble(), _anomalousTraffic[i].y);
        }
      });
    });
  }

  void _triggerAlert(String title, String desc, ThreatLevel level) {
    if (!mounted) return;
    setState(() {
      _logs.insert(0, SecurityEvent(title, desc, level));
      if (level == ThreatLevel.critical) {
        _isNetworkSecured = false;
        _activeThreatMessage = desc;
        _pulseController.duration = const Duration(milliseconds: 300); // Pulsation rapide
        _pulseController.repeat(reverse: true);
      } else if (level == ThreatLevel.warning && _isNetworkSecured) {
        _isNetworkSecured = false;
        _activeThreatMessage = desc;
      }
    });
  }

  // ==========================================
  // SYSTÈME DE NOTIFICATION CYBER
  // ==========================================
  Widget _buildCyberAlertBanner() {
    if (_isNetworkSecured && !_isDdosAttack) return const SizedBox.shrink();

    Color accentColor = !_isNetworkSecured ? kRed : Colors.orangeAccent;
    IconData icon = !_isNetworkSecured ? CupertinoIcons.clear_thick : CupertinoIcons.exclamationmark_shield_fill;
    String title = !_isNetworkSecured ? "VIOLATION DE SÉCURITÉ (CRITIQUE)" : "ANOMALIE RÉSEAU";

    Widget alert = Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPanelColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
        boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: -2)],
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(_activeThreatMessage, style: TextStyle(color: Colors.blueGrey[300], fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );

    return !_isNetworkSecured ? AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) => Transform.scale(scale: _pulseAnimation.value, child: alert)
    ) : alert;
  }

  // ==========================================
  // BUILD PRINCIPAL
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: const Text('Security & IDS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [_buildStatusBadge()],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: kCyan,
          labelColor: kCyan,
          unselectedLabelColor: Colors.blueGrey[600],
          tabs: const [
            Tab(icon: Icon(CupertinoIcons.shield_lefthalf_fill), text: "Radar IDS"),
            Tab(icon: Icon(CupertinoIcons.graph_square), text: "Volumétrie"),
            Tab(icon: Icon(CupertinoIcons.device_desktop), text: "Endpoints NAC"),
            Tab(icon: Icon(CupertinoIcons.doc_text_fill), text: "Forensics Logs"),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: _buildCyberAlertBanner()),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildRadarTab(),
                  _buildTrafficTab(),
                  _buildNacTab(),
                  _buildLogsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      margin: const EdgeInsets.only(right: 24, top: 12, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _isNetworkSecured ? Colors.greenAccent.withValues(alpha: 0.1) : kRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _isNetworkSecured ? Colors.greenAccent : kRed),
      ),
      child: Row(
        children: [
          Icon(_isNetworkSecured ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.exclamationmark_shield_fill, color: _isNetworkSecured ? Colors.greenAccent : kRed, size: 14),
          const SizedBox(width: 6),
          Text(_isNetworkSecured ? "SECURE" : "BREACH", style: TextStyle(color: _isNetworkSecured ? Colors.greenAccent : kRed, fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }

  // ==========================================
  // ONGLET 1 : RADAR IDS
  // ==========================================
  Widget _buildRadarTab() {
    Color glowColor = _isNetworkSecured ? Colors.greenAccent : kRed;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Bouclier Périphérique (Gateway)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: kPanelColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: glowColor.withValues(alpha: 0.3)),
                  boxShadow: [BoxShadow(color: glowColor.withValues(alpha: 0.15 * (_isNetworkSecured ? 1 : _pulseAnimation.value)), blurRadius: 30 * (_isNetworkSecured ? 1 : _pulseAnimation.value))],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Transform.scale(
                          scale: _isNetworkSecured ? 1.0 : _pulseAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: glowColor.withValues(alpha: 0.1)),
                            child: Icon(_isNetworkSecured ? CupertinoIcons.shield_lefthalf_fill : CupertinoIcons.shield_slash_fill, color: glowColor, size: 48),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Routeur Core (L3)", style: TextStyle(color: Colors.blueGrey[300], fontSize: 14)),
                              const SizedBox(height: 8),
                              Text("192.168.1.1", style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              Text(_gatewayMacDisplay, style: GoogleFonts.jetBrainsMono(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!_isNetworkSecured) ...[
                      const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider(color: Colors.white12)),
                      SizedBox(
                        width: double.infinity, height: 45,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white),
                          icon: const Icon(CupertinoIcons.nosign, size: 18),
                          label: const Text("ISOLER L'ATTAQUANT & RESTAURER L'ARP", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () {
                            setState(() {
                              _isNetworkSecured = true;
                              _activeThreatMessage = "";
                              _pulseController.duration = const Duration(seconds: 1); // Retour lent
                              _logs.insert(0, SecurityEvent("Remédiation Appliquée", "L'accès réseau a été révoqué. Table ARP restaurée.", ThreatLevel.info));
                            });
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Menace neutralisée."), backgroundColor: Colors.greenAccent));
                          },
                        ),
                      )
                    ]
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ONGLET 2 : VOLUMÉTRIE & DDOS
  // ==========================================
  Widget _buildTrafficTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Analyse Comportementale Volumétrique", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Détection des attaques par déni de service (DDoS) et exfiltration.", style: TextStyle(color: Colors.blueGrey[400], fontSize: 12)),
          const SizedBox(height: 24),

          Container(
            height: 250,
            padding: const EdgeInsets.only(top: 24, right: 24, left: 12, bottom: 12),
            decoration: BoxDecoration(color: kPanelColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.white10, strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => Text("${v.toInt()} Mb", style: TextStyle(color: Colors.blueGrey[400], fontSize: 10)))),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0, maxX: 19, minY: 0, maxY: 100,
                lineBarsData: [
                  // Trafic Normal (Baseline)
                  LineChartBarData(spots: _normalTraffic, isCurved: true, color: kCyan, barWidth: 2, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: kCyan.withValues(alpha: 0.1))),
                  // Trafic Anormal (Pic)
                  if (_isDdosAttack)
                    LineChartBarData(spots: _anomalousTraffic, isCurved: true, color: kRed, barWidth: 3, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: kRed.withValues(alpha: 0.3))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_isDdosAttack)
            SizedBox(
              width: double.infinity, height: 45,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
                icon: const Icon(CupertinoIcons.speedometer, size: 18),
                label: const Text("ACTIVER LE RATE LIMITING (BGP Blackhole)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () {
                  setState(() {
                    _isDdosAttack = false;
                    if (_isNetworkSecured) _activeThreatMessage = ""; // Clear banner if no other threats
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trafic illégitime rejeté au niveau du FAI (Blackhole)."), backgroundColor: Colors.orangeAccent));
                },
              ),
            )
        ],
      ),
    );
  }

  // ==========================================
  // ONGLET 3 : NAC (Network Access Control)
  // ==========================================
  Widget _buildNacTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _endpoints.length,
      itemBuilder: (context, index) {
        final device = _endpoints[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kPanelColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: device.isQuarantined ? Colors.blueGrey : (device.isTrusted ? Colors.white.withValues(alpha: 0.05) : kRed.withValues(alpha: 0.5))),
          ),
          child: Row(
            children: [
              Icon(device.isQuarantined ? CupertinoIcons.lock_fill : (device.isTrusted ? CupertinoIcons.device_laptop : CupertinoIcons.exclamationmark_triangle_fill), color: device.isQuarantined ? Colors.blueGrey : (device.isTrusted ? kCyan : kRed), size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.ip, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text("${device.mac} • ${device.os}", style: TextStyle(color: Colors.blueGrey[400], fontSize: 11)),
                  ],
                ),
              ),
              if (!device.isQuarantined && !device.isTrusted)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white, minimumSize: const Size(0, 32)),
                  onPressed: () => setState(() => device.isQuarantined = true),
                  child: const Text("Quarantaine", style: TextStyle(fontSize: 10)),
                )
              else if (device.isQuarantined)
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.blueGrey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)), child: const Text("ISOLÉ", style: TextStyle(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.bold)))
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // ONGLET 4 : FORENSICS LOGS (Timeline)
  // ==========================================
  Widget _buildLogsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final event = _logs[index];
        Color indicatorColor = event.level == ThreatLevel.critical ? kRed : (event.level == ThreatLevel.warning ? Colors.orangeAccent : kCyan);
        IconData indicatorIcon = event.level == ThreatLevel.critical ? CupertinoIcons.clear_thick : (event.level == ThreatLevel.warning ? CupertinoIcons.exclamationmark : CupertinoIcons.info);

        return TimelineTile(
          isFirst: index == 0,
          isLast: index == _logs.length - 1,
          beforeLineStyle: LineStyle(color: Colors.white.withValues(alpha: 0.1), thickness: 2),
          indicatorStyle: IndicatorStyle(
            width: 30, height: 30,
            indicator: Container(
              decoration: BoxDecoration(color: indicatorColor.withValues(alpha: 0.2), shape: BoxShape.circle, border: Border.all(color: indicatorColor, width: 2)),
              child: Center(child: Icon(indicatorIcon, size: 14, color: indicatorColor)),
            ),
          ),
          endChild: Container(
            margin: const EdgeInsets.only(left: 16, bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kPanelColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(event.title, style: TextStyle(color: indicatorColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text("${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}:${event.timestamp.second.toString().padLeft(2, '0')}", style: GoogleFonts.jetBrainsMono(color: Colors.white54, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(event.description, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        );
      },
    );
  }
}