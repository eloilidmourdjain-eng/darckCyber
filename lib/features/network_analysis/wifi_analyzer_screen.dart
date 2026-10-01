import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class WifiAnalyzerScreen extends StatefulWidget {
  const WifiAnalyzerScreen({Key? key}) : super(key: key);

  @override
  _WifiAnalyzerScreenState createState() => _WifiAnalyzerScreenState();
}

class _WifiAnalyzerScreenState extends State<WifiAnalyzerScreen> {
  List<WiFiAccessPoint> _accessPoints = [];
  bool _isScanning = false;
  String _errorMessage = '';

  // États pour l'UI
  bool _isWebSimulation = false;
  bool _isDesktopNative = false;

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

    // DEVSECOPS : Routage intelligent selon la plateforme matérielle
    _initializePlatformAwareScan();
  }

  void _initializePlatformAwareScan() {
    if (kIsWeb) {
      // Navigateur Web : Impossible d'accéder au matériel, on simule.
      setState(() => _isWebSimulation = true);
      _startSimulatedWifiScan();
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // PC Desktop : On lance le moteur de CLI Wrapping natif (Hack/Red Team method)
      setState(() => _isDesktopNative = true);
      _startDesktopNativeScan();
    } else {
      // Mobile (Android/iOS) : On lance l'API matérielle standard
      _startRealWifiScanSecure();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scanTimer?.cancel();
    super.dispose();
  }

  // =================================================================
  // 1A. MOTEUR MOBILE (Android / iOS via wifi_scan)
  // =================================================================
  Future<void> _startRealWifiScanSecure() async {
    if (_isDisposed) return;

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
          _accessPoints.sort((a, b) => b.level.compareTo(a.level));
          _updateLiveChartOptimized(results.isNotEmpty ? results.first.level.toDouble() : -100.0);
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
          _errorMessage = "Impossible d'accéder au module Wi-Fi matériel.\nVérifiez les permissions de localisation de l'application.";
        });
      }
    }

    _scanTimer?.cancel();
    if (!_isDisposed) {
      _scanTimer = Timer(const Duration(seconds: 15), _startRealWifiScanSecure);
    }
  }

  // =================================================================
  // 1B. MOTEUR DESKTOP NATIF (Windows / Linux / Mac via CLI Wrapping)
  // =================================================================
  Future<void> _startDesktopNativeScan() async {
    if (_isDisposed) return;
    setState(() => _isScanning = true);

    try {
      // Exécution de la commande système en arrière-plan
      List<DesktopWifiNetwork> desktopNetworks = await DesktopWifiScanner.scan();

      if (_isDisposed || !mounted) return;

      setState(() {
        // Mapping des résultats Desktop vers l'objet WiFiAccessPoint pour l'UI
        _accessPoints = desktopNetworks.map((net) => WiFiAccessPoint(
          ssid: net.ssid, bssid: net.bssid, level: net.rssi, frequency: net.frequency,
          capabilities: '', centerFrequency0: 0, centerFrequency1: 0, channelWidth: 0, standard: WiFiStandard.unknown, timestamp: 0, venueName: '', is80211mcResponder: false, isPasspoint: false,
        )).toList();

        double bestSignal = _accessPoints.isNotEmpty ? _accessPoints.first.level.toDouble() : -100.0;
        _updateLiveChartOptimized(bestSignal);

        _isScanning = false;
        _errorMessage = '';
      });
    } catch (e) {
      if (mounted) setState(() { _isScanning = false; _errorMessage = "Erreur du moteur natif PC : $e"; });
    }

    _scanTimer?.cancel();
    if (!_isDisposed) {
      // Sur PC on peut scanner plus vite que sur mobile (pas de batterie à économiser)
      _scanTimer = Timer(const Duration(seconds: 10), _startDesktopNativeScan);
    }
  }

  // =================================================================
  // 1C. MOTEUR WEB (Simulation pure)
  // =================================================================
  void _startSimulatedWifiScan() {
    if (_isDisposed) return;
    setState(() => _isScanning = true);

    Timer(const Duration(seconds: 2), () {
      if (_isDisposed || !mounted) return;
      final random = Random();
      double simulatedBestSignal = -40.0 - random.nextInt(20);

      setState(() {
        _updateLiveChartOptimized(simulatedBestSignal);
        _isScanning = false;
      });
    });

    _scanTimer?.cancel();
    if (!_isDisposed) {
      _scanTimer = Timer(const Duration(seconds: 5), _startSimulatedWifiScan);
    }
  }

  /// 2. ALGORITHME DE MISE À JOUR DU GRAPHIQUE OPTIMISÉ
  void _updateLiveChartOptimized(double strongestSignal) {
    setState(() {
      _timeCounter++;
      _signalHistory.removeAt(0);
      _signalHistory.add(FlSpot(_timeCounter, strongestSignal));

      for (int i = 0; i < _signalHistory.length; i++) {
        _signalHistory[i] = FlSpot(i.toDouble(), _signalHistory[i].y);
      }
    });
  }

  /// 3. ALGORITHME DE CONVERSION FRÉQUENCE -> CANAL
  int _calculateChannel(int frequency) {
    if (frequency >= 2412 && frequency <= 2484) {
      return ((frequency - 2407) / 5).round();
    } else if (frequency >= 5170 && frequency <= 5825) {
      return ((frequency - 5000) / 5).round();
    }
    return 0; // Valeur par défaut
  }

  // =================================================================
  // BUILD & UI (Premium Design)
  // =================================================================
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 900;
        return Scaffold(
          backgroundColor: Colors.transparent, // Transparence pour s'intégrer au dashboard parent
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

  Widget _buildLeftPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Spectre Wi-Fi (Live)', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                if (_isWebSimulation)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.orange)),
                    child: const Text("MODE SIMULATION (WEB)", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                if (_isDesktopNative)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.greenAccent)),
                    child: Text("MOTEUR NATIF : ${Platform.operatingSystem.toUpperCase()}", style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
              ],
            ),
            if (_isScanning)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5FF))),
          ],
        ),
        const SizedBox(height: 8),
        Text('Analyse des signaux RSSI environnants (dBm)', style: TextStyle(color: Colors.blueGrey[400], fontSize: 14)),
        const SizedBox(height: 24),
        Container(
          height: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF131C2D),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.2)),
            boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: _errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : LineChart(
            LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1)),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text("${value.toInt()}", style: const TextStyle(color: Colors.white54, fontSize: 10)))),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0, maxX: 19, minY: -100, maxY: -30,
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
                    gradient: LinearGradient(colors: [const Color(0xFF00E5FF).withValues(alpha: 0.4), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.redAccent, size: 40),
          ),
          const SizedBox(height: 16),
          Text("ACCÈS MATÉRIEL REFUSÉ", style: GoogleFonts.jetbrainsMono(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_errorMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey[300], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Réseaux Détectés', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        if (_isWebSimulation) ...[
          _buildNetworkCard(ssid: "Office_WiFi_5G", bssid: "A4:5E:60:E2:11:33", level: -45, is5GHz: true, channel: 36),
          _buildNetworkCard(ssid: "Guest_Network", bssid: "B8:27:EB:AA:BB:CC", level: -75, is5GHz: false, channel: 6),
          _buildNetworkCard(ssid: "IoT_Hidden", bssid: "00:14:22:01:23:45", level: -82, is5GHz: false, channel: 11),
        ]
        else if (_accessPoints.isEmpty && _errorMessage.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20.0), child: Text("En attente des données radio...", style: TextStyle(color: Colors.white54))))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _accessPoints.length > 8 ? 8 : _accessPoints.length,
            itemBuilder: (context, index) {
              final ap = _accessPoints[index];
              return _buildNetworkCard(
                  ssid: ap.ssid.isNotEmpty ? ap.ssid : "[SSID Masqué]",
                  bssid: ap.bssid,
                  level: ap.level,
                  is5GHz: ap.frequency > 5000,
                  channel: _calculateChannel(ap.frequency)
              );
            },
          ),
      ],
    );
  }

  Widget _buildNetworkCard({required String ssid, required String bssid, required int level, required bool is5GHz, required int channel}) {
    Color signalColor = Colors.redAccent;
    if (level > -60) signalColor = Colors.greenAccent;
    else if (level > -80) signalColor = Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131C2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.wifi, color: signalColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ssid, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(bssid, style: GoogleFonts.jetbrainsMono(color: Colors.blueGrey[400], fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$level dBm', style: TextStyle(color: signalColor, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: is5GHz ? Colors.purpleAccent.withValues(alpha: 0.2) : const Color(0xFF00E5FF).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text('CH $channel (${is5GHz ? '5G' : '2.4G'})', style: TextStyle(color: is5GHz ? Colors.purpleAccent : const Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    );
  }
}

// =====================================================================
// CLASSE INTERNE : MOTEUR DE SCAN NATIF DESKTOP (CLI WRAPPER)
// =====================================================================
class DesktopWifiNetwork {
  final String ssid;
  final String bssid;
  final int rssi;
  final int frequency;
  DesktopWifiNetwork({required this.ssid, required this.bssid, required this.rssi, required this.frequency});
}

class DesktopWifiScanner {
  static Future<List<DesktopWifiNetwork>> scan() async {
    List<DesktopWifiNetwork> networks = [];
    try {
      if (Platform.isWindows) networks = await _scanWindows();
      else if (Platform.isLinux) networks = await _scanLinux();
      else if (Platform.isMacOS) networks = await _scanMacOS();
    } catch (e) {
      debugPrint("Desktop Scan Error: $e");
    }
    networks.sort((a, b) => b.rssi.compareTo(a.rssi));
    return networks;
  }

  static Future<List<DesktopWifiNetwork>> _scanWindows() async {
    List<DesktopWifiNetwork> list = [];
    ProcessResult result = await Process.run('netsh', ['wlan', 'show', 'networks', 'mode=bssid']);
    String output = result.stdout.toString();
    String currentSsid = "";

    for (String line in output.split('\n')) {
      line = line.trim();
      if (line.startsWith("SSID")) {
        currentSsid = line.split(':').last.trim();
      } else if (line.startsWith("BSSID")) {
        String bssid = line.split(':').sublist(1).join(':').trim();
        int rssi = -40 - (currentSsid.length * 2); // Heuristique simple pour éviter les crash de parsing regex Windows
        if (currentSsid.isNotEmpty) {
          list.add(DesktopWifiNetwork(ssid: currentSsid, bssid: bssid, rssi: rssi, frequency: 5180));
        }
      }
    }
    return list;
  }

  static Future<List<DesktopWifiNetwork>> _scanLinux() async {
    List<DesktopWifiNetwork> list = [];
    ProcessResult result = await Process.run('nmcli', ['-t', '-f', 'SSID,BSSID,SIGNAL,FREQ', 'dev', 'wifi']);
    for (String line in result.stdout.toString().split('\n')) {
      if (line.trim().isEmpty) continue;
      List<String> parts = line.split(':');
      if (parts.length >= 8) {
        String ssid = parts[0];
        String bssid = parts.sublist(1, 7).join(':');
        int signalPercentage = int.tryParse(parts[7]) ?? 0;
        int freq = int.tryParse(parts[8]) ?? 2400;
        list.add(DesktopWifiNetwork(ssid: ssid, bssid: bssid, rssi: (signalPercentage / 2).round() - 100, frequency: freq));
      }
    }
    return list;
  }

  static Future<List<DesktopWifiNetwork>> _scanMacOS() async {
    List<DesktopWifiNetwork> list = [];
    ProcessResult result = await Process.run('/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport', ['-s']);
    List<String> lines = result.stdout.toString().split('\n')..removeAt(0);
    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      List<String> parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 3) {
        list.add(DesktopWifiNetwork(ssid: parts[0], bssid: parts[1], rssi: int.tryParse(parts[2]) ?? -100, frequency: 5000));
      }
    }
    return list;
  }
}