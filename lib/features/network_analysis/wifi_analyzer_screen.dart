import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WifiAnalyzerScreen extends StatefulWidget {
  const WifiAnalyzerScreen({Key? key}) : super(key: key);

  @override
  _WifiAnalyzerScreenState createState() => _WifiAnalyzerScreenState();
}

class _WifiAnalyzerScreenState extends State<WifiAnalyzerScreen> {
  List<WiFiAccessPoint> _accessPoints = [];
  bool _isScanning = false;
  String _errorMessage = '';

  // Algorithme de buffer optimisé pour le graphique en temps réel
  final List<FlSpot> _signalHistory = [];
  double _timeCounter = 0;
  Timer? _scanTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // Initialisation sécurisée du buffer de données
    for (int i = 0; i < 20; i++) {
      _signalHistory.add(FlSpot(i.toDouble(), -100)); // -100 dBm (Signal de référence mort)
    }
    _timeCounter = 19;
    _startRealWifiScanSecure();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scanTimer?.cancel();
    super.dispose();
  }

  /// 1. ALGORITHME DE BALAYAGE MATÉRIEL SÉCURISÉ (Anti-Race Condition)
  Future<void> _startRealWifiScanSecure() async {
    if (_isDisposed) return;

    // Gestion stricte de la Sandbox iOS
    if (Platform.isIOS) {
      if (!mounted) return;
      setState(() => _errorMessage = "Sandbox Apple : Scan Wi-Fi environnant restreint sur iOS.\nSeul le réseau actif est accessible.");
      return;
    }

    if (!mounted) return;
    setState(() => _isScanning = true);

    try {
      final canScan = await WiFiScan.instance.canStartScan();
      if (canScan == CanStartScan.yes) {
        await WiFiScan.instance.startScan();
        final results = await WiFiScan.instance.getScannedResults();

        if (_isDisposed || !mounted) return;

        setState(() {
          _accessPoints = results;
          // Tri sécurisé par puissance de signal descendante
          _accessPoints.sort((a, b) => b.level.compareTo(a.level));
          _updateLiveChartOptimized(results);
          _isScanning = false;
          _errorMessage = '';
        });
      } else {
        if (_isDisposed || !mounted) return;
        setState(() {
          _isScanning = false;
          _errorMessage = "Limitation OS / Throttling : Patientez avant le prochain balayage radio.";
        });
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          _isScanning = false;
          _errorMessage = "Erreur critique du sous-système Wi-Fi : $e";
        });
      }
    }

    // SÉCURITÉ ARCHITECTURALE : Utilisation d'un Timer périodique propre pour éviter les fuites de récursion
    _scanTimer?.cancel();
    if (!_isDisposed) {
      _scanTimer = Timer(const Duration(seconds: 15), _startRealWifiScanSecure);
    }
  }

  /// 2. ALGORITHME DE MISE À JOUR DU GRAPHIQUE OPTIMISÉ (O(1) au lieu de O(N))
  void _updateLiveChartOptimized(List<WiFiAccessPoint> results) {
    if (results.isEmpty) return;

    double strongestSignal = results.first.level.toDouble();

    setState(() {
      _timeCounter++;
      _signalHistory.removeAt(0);
      _signalHistory.add(FlSpot(_timeCounter, strongestSignal));

      // OPTIMISATION : Mise à jour directe des abscisses sans réindexation lourde redondante
      for (int i = 0; i < _signalHistory.length; i++) {
        _signalHistory[i] = FlSpot(i.toDouble(), _signalHistory[i].y);
      }
    });
  }

  /// 3. ALGORITHME DE CONVERSION FRÉQUENCE -> CANAL
  int _calculateChannel(int frequency) {
    if (frequency >= 2412 && frequency <= 2484) {
      return ((frequency - 2407) / 5).round(); // Bande 2.4 GHz
    } else if (frequency >= 5170 && frequency <= 5825) {
      return ((frequency - 5000) / 5).round(); // Bande 5 GHz
    }
    return 0; // Inconnu / Bande non standard
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 900;
        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: isDesktop ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildLeftPanel()),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildRightPanel()),
                ],
              ) : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeftPanel(),
                    const SizedBox(height: 24),
                    _buildRightPanel(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- PANNEAU GAUCHE : LE GRAPHIQUE EN TEMPS RÉEL ---
  Widget _buildLeftPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Spectre Wi-Fi (Live)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            if (_isScanning)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Analyse des signaux RSSI environnants (dBm)', style: TextStyle(color: Colors.blueGrey[400], fontSize: 14)),
        const SizedBox(height: 24),
        Container(
          height: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center))
              : LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text("${value.toInt()} dBm", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  ),
                ),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 19,
              minY: -100,
              maxY: -30,
              lineBarsData: [
                LineChartBarData(
                  spots: _signalHistory,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: const Color(0xFF00E5FF),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00E5FF).withOpacity(0.4),
                        const Color(0xFF00E5FF).withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- PANNEAU DROIT : LA LISTE DES RÉSEAUX MATÉRIELS ---
  Widget _buildRightPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Réseaux Détectés',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        _accessPoints.isEmpty && _errorMessage.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("En attente des données radio...", style: TextStyle(color: Colors.white54))))
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _accessPoints.length > 8 ? 8 : _accessPoints.length,
          itemBuilder: (context, index) {
            final ap = _accessPoints[index];
            final channel = _calculateChannel(ap.frequency);
            final is5GHz = ap.frequency > 5000;

            Color signalColor = Colors.redAccent;
            if (ap.level > -60) signalColor = Colors.greenAccent;
            else if (ap.level > -80) signalColor = Colors.orangeAccent;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.02)),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.wifi, color: signalColor, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ap.ssid.isNotEmpty ? ap.ssid : "[SSID Masqué / Hidden]", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(ap.bssid, style: GoogleFonts.jetBrainsMono(color: Colors.blueGrey[400], fontSize: 11)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${ap.level} dBm', style: TextStyle(color: signalColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: is5GHz ? Colors.purpleAccent.withOpacity(0.2) : Colors.cyanAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'CH $channel (${is5GHz ? '5G' : '2.4G'})',
                          style: TextStyle(color: is5GHz ? Colors.purpleAccent : Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  )
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
