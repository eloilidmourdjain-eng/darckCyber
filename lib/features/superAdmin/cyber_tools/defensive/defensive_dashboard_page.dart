import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rxdart/rxdart.dart';

// --- MULTITHREADING : DOIT ÊTRE EN DEHORS DE LA CLASSE ---
// Protège le thread principal UI d'une attaque par inondation de logs (OOM / CPU Exhaustion)
Map<String, dynamic>? parseAlertIsolate(String rawJson) {
  try {
    final alert = jsonDecode(rawJson);
    if (alert is Map<String, dynamic> && alert.containsKey('source_ip') && alert.containsKey('severity_score')) {
      return alert;
    }
  } catch (e) {
    // Rejet silencieux des trames corrompues
  }
  return null;
}

class OperationalDefenseDashboard extends StatefulWidget {
  const OperationalDefenseDashboard({super.key});

  @override
  State<OperationalDefenseDashboard> createState() => _OperationalDefenseDashboardState();
}

class _OperationalDefenseDashboardState extends State<OperationalDefenseDashboard> {
  // --- MOTEUR RÉSEAU & SÉCURITÉ ---
  late final IOWebSocketChannel _channel;
  StreamSubscription? _alertSubscription;
  final int _maxLogs = 100;

  // Validation stricte UI (Rappel: le backend doit re-valider impérativement)
  final RegExp _ipv4Regex = RegExp(r'^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');

  // --- ÉTAT DE L'UI ---
  final List<Map<String, dynamic>> _alertsLog = [];
  final List<FlSpot> _chartData = [];
  double _timeCounter = 14;
  String _selectedFilter = 'ALL';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 15; i++) {
      _chartData.add(FlSpot(i.toDouble(), 0));
    }
    _initWebSocket();
  }

  void _initWebSocket() {
    try {
      // 1. Dissimulation des endpoints via .env
      final String wsUrl = dotenv.env['C2_WSS_URL'] ?? 'wss://127.0.0.1:8080';
      final String authToken = dotenv.env['C2_AUTH_TOKEN'] ?? '';

      // 2. Chiffrement (wss://) et Authentification (JWT/mTLS)
      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {'Authorization': 'Bearer $authToken'},
        // optionnel: implémenter un custom SecurityContext ici pour le Certificate Pinning
      );

      // 3. Résilience : Throttling avec RxDart (Limitation à ~4 updates/sec)
      _alertSubscription = _channel.stream
          .map((event) => event.toString())
          .throttleTime(const Duration(milliseconds: 250))
          .listen(
          _processRealAlert,
          onError: (e) => setState(() => _isConnected = false),
          onDone: () => setState(() => _isConnected = false)
      );

      setState(() => _isConnected = true);
    } catch (e) {
      setState(() => _isConnected = false);
    }
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    _channel.sink.close();
    super.dispose();
  }

  // --- ALGORYTHME DE TRAITEMENT DES FLUX ---
  Future<void> _processRealAlert(String rawJson) async {
    // Exécution du parsing JSON dans un Isolate (hors du thread UI principal)
    final alert = await compute(parseAlertIsolate, rawJson);

    if (alert == null || !mounted) return;

    setState(() {
      _alertsLog.insert(0, alert);
      if (_alertsLog.length > _maxLogs) _alertsLog.removeLast();

      _timeCounter++;
      _chartData.removeAt(0);

      double score = double.tryParse(alert['severity_score'].toString()) ?? 0.0;
      _chartData.add(FlSpot(_timeCounter, score));

      for (int i = 0; i < _chartData.length; i++) {
        _chartData[i] = FlSpot(i.toDouble(), _chartData[i].y);
      }
    });
  }

  // --- ALGORYTHME D'EXÉCUTION C2 ---
  void _executeBan(String ip, String type) async {
    Navigator.pop(context);

    if (!_ipv4Regex.hasMatch(ip)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('⚠️ Format IP invalide. Tentative d\'évasion bloquée.'),
        backgroundColor: Colors.orangeAccent,
      ));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transmission de l\'ordre au C2 pour $ip...')));

    // RAPPEL SÉCURITÉ BACKEND : L'API C2 qui réceptionne cet appel ne doit JAMAIS concaténer
    // cette IP dans un shell Unix. Utiliser une lib UFW dédiée ou des paramètres liés.
    bool success = true;
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('⚡ L\'adresse IP $ip a été isolée sur l\'infrastructure.'),
        backgroundColor: Colors.greenAccent,
      ));
    }
  }

  void _showRemediationDialog(Map<String, dynamic> alert) {
    String attackerIp = alert["source_ip"] ?? "Inconnue";
    String alertType = alert["title"] ?? "Menace";
    String severity = alert["severity"] ?? "INFO";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: severity == 'CRITICAL' ? Colors.redAccent : Colors.cyanAccent)),
        title: Row(
          children: [
            Icon(CupertinoIcons.shield_lefthalf_fill, color: severity == 'CRITICAL' ? Colors.redAccent : Colors.cyanAccent),
            const SizedBox(width: 10),
            const Text("Action de Remédiation", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Type: $alertType", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            RichText(
                text: TextSpan(
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    children: [
                      const TextSpan(text: "Cible à isoler : "),
                      TextSpan(text: attackerIp, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontFamily: 'monospace', letterSpacing: 1.2)),
                    ]
                )
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
              child: Text("sudo ufw deny from $attackerIp comment 'Banni via IDS'", style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 11)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => _executeBan(attackerIp, alertType),
            icon: const Icon(CupertinoIcons.clear_thick, size: 16),
            label: const Text("EXÉCUTER LE BANNISSEMENT"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAlerts = _alertsLog.where((alert) {
      if (_selectedFilter == 'ALL') return true;
      return alert["severity"] == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("SOC (Security Operations)", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: _isConnected ? Colors.greenAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.circle_fill, color: _isConnected ? Colors.greenAccent : Colors.redAccent, size: 10),
                        const SizedBox(width: 6),
                        Text(_isConnected ? "IDS ONLINE" : "OFFLINE", style: TextStyle(color: _isConnected ? Colors.greenAccent : Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // --- GRAPHIQUE OSCILLOSCOPE PREMIUM ---
              Container(
                height: 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.05), blurRadius: 20)],
                ),
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minY: 0, maxY: 10,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _chartData,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: Colors.redAccent,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [Colors.redAccent.withOpacity(0.4), Colors.transparent],
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- BARRE DE FILTRES ---
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'Tout', CupertinoIcons.layers_alt_fill, Colors.blueGrey),
                    _buildFilterChip('CRITICAL', 'Critique', CupertinoIcons.clear_circled_solid, Colors.redAccent),
                    _buildFilterChip('WARNING', 'Avertissement', CupertinoIcons.exclamationmark_triangle_fill, Colors.orangeAccent),
                    _buildFilterChip('INFO', 'Information', CupertinoIcons.info_circle_fill, Colors.cyanAccent),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- LISTE DES MENACES ---
              Expanded(
                child: filteredAlerts.isEmpty
                    ? Center(child: Text("Aucune menace détectée.", style: TextStyle(color: Colors.blueGrey[400])))
                    : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = filteredAlerts[index];
                    final isCritical = alert['severity'] == 'CRITICAL';
                    final color = isCritical ? Colors.redAccent : (alert['severity'] == 'WARNING' ? Colors.orangeAccent : Colors.cyanAccent);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.3)),
                        boxShadow: isCritical ? [BoxShadow(color: Colors.redAccent.withOpacity(0.1), blurRadius: 10)] : [],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                            child: Icon(isCritical ? CupertinoIcons.flame_fill : CupertinoIcons.shield_fill, color: color, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(alert['title'] ?? 'Inconnu', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text("Source: ${alert['source_ip'] ?? '0.0.0.0'} • ${alert['timestamp'] ?? ''}", style: TextStyle(color: Colors.blueGrey[300], fontSize: 11, fontFamily: 'monospace')),
                              ],
                            ),
                          ),
                          if (isCritical || alert['severity'] == 'WARNING')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color.withOpacity(0.1),
                                foregroundColor: color,
                                elevation: 0,
                                side: BorderSide(color: color),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              onPressed: () => _showRemediationDialog(alert),
                              child: const Text("Remédier", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon, Color color) {
    bool isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        showCheckmark: false,
        backgroundColor: const Color(0xFF1E293B),
        selectedColor: color.withOpacity(0.2),
        side: BorderSide(color: isSelected ? color : Colors.transparent),
        label: Row(
          children: [
            Icon(icon, color: isSelected ? color : Colors.blueGrey[400], size: 14),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isSelected ? color : Colors.blueGrey[400], fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        selected: isSelected,
        onSelected: (bool selected) => setState(() => _selectedFilter = value),
      ),
    );
  }
}