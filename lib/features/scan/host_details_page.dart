import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class HostDetailsPage extends StatefulWidget {
  final String ip;
  final String mac;
  final String osType;
  final String vendor;

  const HostDetailsPage({
    super.key,
    required this.ip,
    required this.mac,
    required this.osType,
    required this.vendor,
  });

  @override
  State<HostDetailsPage> createState() => _HostDetailsPageState();
}

class _HostDetailsPageState extends State<HostDetailsPage> {
  final Color kBgColor = const Color(0xFF070B14);
  final Color kCardColor = const Color(0xFF131C2D);
  final Color kCyan = const Color(0xFF00E5FF);

  // --- VARIABLES POUR LE PING CONTINU ---
  final List<FlSpot> _pingData = [];
  double _timeX = 19;
  Timer? _pingTimer;
  int _currentPing = 0;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 20; i++) {
      _pingData.add(FlSpot(i.toDouble(), 10.0));
    }
    _startContinuousPing();
  }

  void _startContinuousPing() {
    _pingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _timeX++;
        _pingData.removeAt(0);

        // Simulation d'un ping réel vers la machine cible
        _currentPing = 10 + Random().nextInt(15); // Ping entre 10 et 25ms
        if (Random().nextInt(100) > 95) _currentPing = 150; // Simulation d'un pic de latence (Lag)

        _pingData.add(FlSpot(_timeX, _currentPing.toDouble()));

        for (int i = 0; i < _pingData.length; i++) {
          _pingData[i] = FlSpot(i.toDouble(), _pingData[i].y);
        }
      });
    });
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }

  void _executeAction(String action) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(action), backgroundColor: const Color(0xFF1E3A8A), behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    IconData osIcon = CupertinoIcons.device_laptop;
    if (widget.osType.contains('Linux') || widget.osType.contains('Android')) osIcon = CupertinoIcons.device_phone_portrait;
    if (widget.osType.contains('Windows')) osIcon = CupertinoIcons.square_grid_2x2_fill;
    if (widget.osType.contains('Routeur') || widget.osType.contains('Gateway')) osIcon = CupertinoIcons.rocket_fill;

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: const Text('Investigation Endpoint', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- EN-TÊTE IDENTIFICATION ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: kCyan.withValues(alpha: 0.3)), boxShadow: [BoxShadow(color: kCyan.withValues(alpha: 0.05), blurRadius: 20)]),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kCyan.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(osIcon, color: kCyan, size: 36),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.ip, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(widget.osType, style: TextStyle(color: Colors.blueGrey[300], fontSize: 14)),
                        const SizedBox(height: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: const Text("STATUT : EN LIGNE", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)))
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- GRAPHIQUE PING CONTINU ---
            const Text("LATENCE EN TEMPS RÉEL (ICMP)", style: TextStyle(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            Container(
              height: 150,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
              child: Stack(
                children: [
                  LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false), titlesData: const FlTitlesData(show: false), borderData: FlBorderData(show: false), minY: 0, maxY: 200,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _pingData, isCurved: true, color: _currentPing > 100 ? Colors.redAccent : kCyan, barWidth: 2, dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [(_currentPing > 100 ? Colors.redAccent : kCyan).withValues(alpha: 0.3), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                        ),
                      ],
                    ),
                  ),
                  Positioned(top: 0, right: 0, child: Text("$_currentPing ms", style: GoogleFonts.jetBrainsMono(color: _currentPing > 100 ? Colors.redAccent : kCyan, fontSize: 16, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- OUTILS D'ADMINISTRATION (ACTIONS RAPIDES) ---
            const Text("ACTIONS OPÉRATIONNELLES (L4/L7)", style: TextStyle(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 2.5,
              children: [
                _buildActionBtn(
                    "Terminal SSH (Port 22)",
                    CupertinoIcons.chevron_left_slash_chevron_right,
                    kCyan,
                        () => _executeAction("Lancement du client SSH vers ${widget.ip}... \nÉchange de clés RSA en cours.")
                ),
                _buildActionBtn("Bureau à Distance (RDP)", CupertinoIcons.macwindow, Colors.orangeAccent, () => _executeAction("Connexion RDP sur le port 3389 initiée.")),
                _buildActionBtn("Wake-on-LAN (WoL)", CupertinoIcons.bolt_fill, Colors.yellowAccent, () => _executeAction("Paquet Magic (WoL) envoyé à l'adresse MAC ${widget.mac}")),
                _buildActionBtn("Isoler (Quarantaine L2)", CupertinoIcons.nosign, Colors.redAccent, () => _executeAction("⚠️ Machine placée en quarantaine. Trafic coupé.")),
              ],
            ),
            const SizedBox(height: 32),

            // --- SPÉCIFICATIONS ---
            const Text("SPÉCIFICATIONS RÉSEAU (OSI L2/L3)", style: TextStyle(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
              child: Column(
                children: [
                  _buildDetailRow("Adresse MAC", widget.mac, isMonospace: true),
                  const Divider(color: Colors.white12, height: 24),
                  _buildDetailRow("Constructeur (OUI)", widget.vendor),
                  const Divider(color: Colors.white12, height: 24),
                  _buildDetailRow("VLAN ID", "VLAN 10 (Corporate)"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: color.withValues(alpha: 0.1), foregroundColor: color, side: BorderSide(color: color.withValues(alpha: 0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 8)),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
      onPressed: onTap,
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMonospace = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text(value, style: isMonospace ? GoogleFonts.jetBrainsMono(color: kCyan, fontSize: 13, fontWeight: FontWeight.bold) : const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}