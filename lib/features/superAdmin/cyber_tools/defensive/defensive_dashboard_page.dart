import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rxdart/rxdart.dart';
import 'package:google_fonts/google_fonts.dart';

// --- IMPORTS DES MOTEURS D'AUDIT ET SOAR ---
import 'package:darck_puls/features/superAdmin/cyber_tools/defensive/audit_cli_wrapper.dart';
import 'package:darck_puls/features/superAdmin/cyber_tools/defensive/audit_process_manager.dart';
import 'package:darck_puls/features/superAdmin/cyber_tools/defensive/firewall_api.dart';

// --- MULTITHREADING (Isolates) pour le parsing des alertes ---
Map<String, dynamic>? parseAlertIsolate(String rawJson) {
  try {
    final alert = jsonDecode(rawJson);
    if (alert is Map<String, dynamic> && alert.containsKey('source_ip')) return alert;
  } catch (e) { }
  return null;
}

// --- MODÈLES BLUE TEAM & SOC ---
class EdrAgent {
  final String hostname;
  final String ip;
  final String os;
  final String status;
  bool isIsolated;
  List<Map<String, String>> activeThreats;

  EdrAgent(this.hostname, this.ip, this.os, this.status, {this.isIsolated = false, this.activeThreats = const []});
}

class NidsRule {
  final String sid;
  final String description;
  final String category;
  bool isActive;
  bool dropTraffic;

  NidsRule(this.sid, this.description, this.category, this.isActive, this.dropTraffic);
}

class DefenseDashboardWidget extends StatefulWidget {
  const DefenseDashboardWidget({super.key});

  @override
  State<DefenseDashboardWidget> createState() => _DefenseDashboardWidgetState();
}

class _DefenseDashboardWidgetState extends State<DefenseDashboardWidget> with TickerProviderStateMixin {
  // --- MOTEUR RÉSEAU & SÉCURITÉ ---
  late final IOWebSocketChannel _channel;
  StreamSubscription? _alertSubscription;
  final int _maxLogs = 100;
  final RegExp _ipv4Regex = RegExp(r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$');

  // --- ÉTAT DE L'UI & ONGLETS ---
  late TabController _tabController;
  late TabController _scannerTabController; // Pour les 4 onglets du scanner réseau
  late AnimationController _pulseController;

  final List<Map<String, dynamic>> _alertsLog = [];
  final List<FlSpot> _chartData = [];
  double _timeCounter = 19;
  String _selectedFilter = 'ALL';
  bool _isConnected = false;
  bool _isNetworkSecured = true;

  // --- ÉTATS DU MODULE AUDIT ACTIF (NMAP/TSHARK) ---
  final TextEditingController _targetController = TextEditingController(text: "192.168.1.1");
  final AuditProcessManager _processManager = AuditProcessManager();
  bool _isAuditing = false;
  String _auditConsoleOutput = "Terminal d'Audit Réseau Initialisé.\nEn attente de commande...";
  String _selectedTool = 'nmap';
  String _selectedProfile = 'fast_discovery';

  final Map<String, Map<String, String>> _toolProfiles = {
    'nmap': {
      'fast_discovery': 'Scan Rapide (Ping Sweep)',
      'service_audit': 'Audit des Services & Versions',
    },
    'tshark': {
      'capture_dns': 'Wireshark : Capture Trafic DNS',
      'capture_tcp': 'Wireshark : Capture Trafic TCP',
    },
    'iperf3': {
      'bandwidth_test': 'Test de Bande Passante (10s)',
    },
    'mtr': {
      'diag_route': 'Diagnostic de Routage Dynamique',
    }
  };

  // --- BASES DE DONNÉES SIMULÉES (EDR & NIDS & ASSETS) ---
  final List<EdrAgent> _edrAgents = [
    EdrAgent("SRV-DB-01", "10.0.0.5", "Linux (Ubuntu)", "Sain"),
    EdrAgent("LAPTOP-CEO", "192.168.1.45", "Windows 11", "Infecté", activeThreats: [
      {"pid": "4452", "name": "powershell.exe", "hash": "e3b0c442...495991", "desc": "Exécution de script encodé Base64 (Suspect)"}
    ]),
  ];

  final List<NidsRule> _nidsRules = [
    NidsRule("2010935", "ET SCAN Suspicious inbound to MSSQL port 1433", "Reconnaissance", true, true),
    NidsRule("2024364", "ET MALWARE Win32/Trickbot CnC Checkin", "Malware C2", true, true),
    NidsRule("2013028", "ET POLICY Cleartext Credentials over HTTP", "Policy Violation", true, false),
  ];

  final List<Map<String, String>> _networkAssets = [
    {'ip': '192.168.1.1', 'mac': '00:1A:2B:3C:4D:5E', 'role': 'Passerelle / Routeur L3', 'status': 'Sécurisé'},
    {'ip': '192.168.1.50', 'mac': 'AA:BB:CC:DD:EE:FF', 'role': 'Serveur Web (Docker)', 'status': 'Alerte'},
    {'ip': '192.168.1.102', 'mac': '11:22:33:44:55:66', 'role': 'Poste Admin (Flutter)', 'status': 'Sécurisé'},
  ];

  final TextEditingController _ctiSearchController = TextEditingController();
  Map<String, dynamic>? _ctiResult;
  bool _isCtiSearching = false;

  // Palette Cyber / Dark Theme
  final Color kBgColor = const Color(0xFF070B14);
  final Color kPanelColor = const Color(0xFF131C2D);
  final Color kCyan = const Color(0xFF00E5FF);
  final Color kRed = const Color(0xFFFF2A55);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this); // 8 Vues principales alignées sur le cahier des charges
    _scannerTabController = TabController(length: 4, vsync: this); // 4 Sous-onglets du Scanner Réseau
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);

    for (int i = 0; i < 20; i++) {
      _chartData.add(FlSpot(i.toDouble(), 0));
    }
    _initWebSocket();
  }

  void _initWebSocket() {
    try {
      final String wsUrl = dotenv.env['C2_WSS_URL'] ?? 'ws://127.0.0.1:8080';
      final String authToken = dotenv.env['C2_AUTH_TOKEN'] ?? '';
      _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl), headers: {'Authorization': 'Bearer $authToken'});

      _alertSubscription = _channel.stream
          .map((event) => event.toString())
          .throttleTime(const Duration(milliseconds: 250))
          .listen(_processRealAlert, onError: (e) => setState(() => _isConnected = false), onDone: () => setState(() => _isConnected = false));

      setState(() => _isConnected = true);
    } catch (e) {
      setState(() => _isConnected = false);
    }
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    _channel.sink.close();
    _tabController.dispose();
    _scannerTabController.dispose();
    _pulseController.dispose();
    _ctiSearchController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _processRealAlert(String rawJson) async {
    final alert = await compute(parseAlertIsolate, rawJson);
    if (alert == null || !mounted) return;

    setState(() {
      _alertsLog.insert(0, alert);
      if (_alertsLog.length > _maxLogs) _alertsLog.removeLast();

      if (alert['severity'] == 'CRITICAL') {
        _isNetworkSecured = false;
        _pulseController.duration = const Duration(milliseconds: 400);
        _pulseController.repeat(reverse: true);
      }

      _timeCounter++;
      _chartData.removeAt(0);
      double score = double.tryParse(alert['severity_score'].toString()) ?? 0.0;
      _chartData.add(FlSpot(_timeCounter, score));
      for (int i = 0; i < _chartData.length; i++) {
        _chartData[i] = FlSpot(i.toDouble(), _chartData[i].y);
      }
    });
  }

  // --- ACTIONS SOAR : BANNISSEMENT RÉEL (IPTABLES VIA SSH) ---
  void _executeBan(String ip) async {
    if (!_ipv4Regex.hasMatch(ip)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Adresse IP invalide pour le bannissement.'), backgroundColor: Colors.redAccent)
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🛡️ [SOAR] Connexion SSH et application de la règle iptables pour $ip...'), backgroundColor: kPanelColor)
    );

    bool success = await OperationalCyberManager.banIpAddress(ip);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Succès : L\'IP $ip a été isolée par le pare-feu.'), backgroundColor: Colors.greenAccent)
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Échec de la liaison SSH pour isoler $ip.'), backgroundColor: kRed)
      );
    }
  }

  void _executeEdrKillProcess(EdrAgent agent, String pid) async {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('EDR: Envoi SIGKILL au PID $pid sur ${agent.hostname}...'), backgroundColor: kPanelColor)
    );
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      agent.activeThreats.removeWhere((t) => t["pid"] == pid);
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Processus malveillant terminé avec succès.'), backgroundColor: Colors.greenAccent)
    );
  }

  // ==========================================
  // BUILD PRINCIPAL (DASHBOARD MULTI-VUES)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: const Text('Darck Puls • SOC & Security Center', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [_buildStatusBadge()],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: kCyan,
          labelColor: kCyan,
          unselectedLabelColor: Colors.blueGrey[600],
          tabs: const [
            Tab(icon: Icon(CupertinoIcons.graph_square_fill), text: "Vue Stratégique"),
            Tab(icon: Icon(CupertinoIcons.waveform), text: "Vue Opérationnelle"),
            Tab(icon: Icon(CupertinoIcons.shield_lefthalf_fill), text: "Vue Analytique SOC"),
            Tab(icon: Icon(CupertinoIcons.globe), text: "Scanner Réseau"),
            Tab(icon: Icon(CupertinoIcons.device_desktop), text: "Wazuh EDR"),
            Tab(icon: Icon(CupertinoIcons.search), text: "Threat Intel"),
            Tab(icon: Icon(CupertinoIcons.layers_alt_fill), text: "Règles NIDS"),
            Tab(icon: Icon(CupertinoIcons.waveform_path), text: "Audit Actif"),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(),
          children: [
            _buildStrategicViewTab(), // 1. Vue Stratégique (RSSI / DSI)
            _buildOperationalViewTab(), // 2. Vue Opérationnelle (Techniciens Réseau)
            _buildAnalyticalViewTab(), // 3. Vue Analytique SOC & Logs Temps Réel
            _buildNetworkScannerTab(), // 4. Scanner Réseau (4 sous-onglets)
            _buildEdrTab(), // 5. Wazuh EDR
            _buildCtiTab(), // 6. Threat Intelligence
            _buildNidsTab(), // 7. Règles NIDS & Suricata
            _buildAuditTab(), // 8. Audit Actif (Nmap, Tshark)
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
        color: _isConnected ? Colors.greenAccent.withValues(alpha: 0.1) : kRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _isConnected ? Colors.greenAccent : kRed),
      ),
      child: Row(
        children: [
          Icon(_isConnected ? CupertinoIcons.circle_fill : CupertinoIcons.clear_thick, color: _isConnected ? Colors.greenAccent : kRed, size: 10),
          const SizedBox(width: 6),
          Text(_isConnected ? "WSS ONLINE" : "OFFLINE", style: GoogleFonts.jetBrainsMono(color: _isConnected ? Colors.greenAccent : kRed, fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }

  // ==========================================
  // 1. VUE STRATÉGIQUE (Direction IT / RSSI)
  // ==========================================
  Widget _buildStrategicViewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("INDICATEURS DE RISQUE GLOBAL (KPIs)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: kPanelColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Score de Risque Réseau", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text("24 / 100", style: GoogleFonts.jetBrainsMono(color: Colors.greenAccent, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text("Niveau de menace : Faible à Modéré", style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: kPanelColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Attaques Bloquées (7j)", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text("1,482", style: GoogleFonts.jetBrainsMono(color: kCyan, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text("+12% par rapport à la semaine dernière", style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text("Répartition Macro des Menaces (Top 5)", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: kPanelColor, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildProgressBar("Brute-Force SSH", 0.45, kRed),
                const SizedBox(height: 12),
                _buildProgressBar("Scans de ports (UFW / Nmap)", 0.30, Colors.orangeAccent),
                const SizedBox(height: 12),
                _buildProgressBar("Tentatives WAF / SQLi", 0.15, kCyan),
                const SizedBox(height: 12),
                _buildProgressBar("Trafic Anormal / Divers", 0.10, Colors.blueGrey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
            Text("${(value * 100).toInt()}%", style: GoogleFonts.jetBrainsMono(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: value, color: color, backgroundColor: Colors.white10, minHeight: 6, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }

  // ==========================================
  // 2. VUE OPÉRATIONNELLE (Techniciens Réseau)
  // ==========================================
  Widget _buildOperationalViewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ÉTAT DES INFRASTRUCTURES & VOLUMÉTRIE", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: kPanelColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Débit Global (WAN/LAN)", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text("845 Mbps", style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text("Charge CPU Sondes : 18%", style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: kPanelColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Paquets Perdus (Drop Rate)", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text("0.02%", style: GoogleFonts.jetBrainsMono(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text("Suricata / Zeek : Opérationnel", style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text("Consommateurs de Bande Passante (Top Talkers)", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: kPanelColor, borderRadius: BorderRadius.circular(16)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _networkAssets.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
              itemBuilder: (context, index) {
                final asset = _networkAssets[index];
                return ListTile(
                  leading: Icon(CupertinoIcons.desktopcomputer, color: kCyan),
                  title: Text(asset['ip']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(asset['role']!, style: TextStyle(color: Colors.blueGrey[400], fontSize: 11)),
                  trailing: Text("142 MB/s", style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 12)),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  // ==========================================
  // 3. VUE ANALYTIQUE SOC & LOGS TEMPS RÉEL
  // ==========================================
  Widget _buildAnalyticalViewTab() {
    final filteredAlerts = _selectedFilter == 'ALL' ? _alertsLog : _alertsLog.where((alert) => alert["severity"] == _selectedFilter).toList();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildFilterChip('ALL', 'Tous les Logs', kCyan),
              _buildFilterChip('CRITICAL', 'Critique (Suricata/Wazuh)', kRed),
              _buildFilterChip('WARNING', 'Avertissement', Colors.orangeAccent),
              _buildFilterChip('INFO', 'Zeek Metadata', Colors.greenAccent),
            ],
          ),
        ),
        Expanded(
          child: filteredAlerts.isEmpty
              ? Center(child: Text("En attente de trames SIEM / Suricata / Zeek...", style: TextStyle(color: Colors.blueGrey[400])))
              : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredAlerts.length,
            itemBuilder: (context, index) {
              final alert = filteredAlerts[index];
              final isCritical = alert['severity'] == 'CRITICAL';
              final color = isCritical ? kRed : (alert['severity'] == 'WARNING' ? Colors.orangeAccent : Colors.greenAccent);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: kPanelColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
                child: Row(
                  children: [
                    Icon(isCritical ? CupertinoIcons.flame_fill : CupertinoIcons.shield_fill, color: color, size: 20),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(alert['title'] ?? 'Événement Inconnu', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text("SRC: ${alert['source_ip']} • Cible: ${alert['target']} • Score: ${alert['severity_score']}", style: GoogleFonts.jetBrainsMono(color: Colors.blueGrey[300], fontSize: 10)),
                        ],
                      ),
                    ),
                    // Bouton SOAR de bannissement réel
                    if (isCritical || alert['severity'] == 'WARNING')
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: color.withValues(alpha: 0.1), foregroundColor: color, elevation: 0),
                        icon: const Icon(CupertinoIcons.hand_raised_fill, size: 14),
                        label: const Text("Bannir l'IP"),
                        onPressed: () => _executeBan(alert['source_ip']),
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

  Widget _buildFilterChip(String value, String label, Color color) {
    bool isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.blueGrey[400], fontSize: 11, fontWeight: FontWeight.bold)),
        selected: isSelected,
        selectedColor: color,
        backgroundColor: kPanelColor,
        showCheckmark: false,
        onSelected: (_) => setState(() => _selectedFilter = value),
      ),
    );
  }

  // ==========================================
  // 4. SCANNER RÉSEAU (4 sous-onglets du cahier des charges)
  // ==========================================
  Widget _buildNetworkScannerTab() {
    return Column(
      children: [
        Container(
          color: kPanelColor,
          child: TabBar(
            controller: _scannerTabController,
            indicatorColor: kCyan,
            labelColor: kCyan,
            unselectedLabelColor: Colors.blueGrey,
            tabs: const [
              Tab(text: "Topologie"),
              Tab(text: "Inventaire"),
              Tab(text: "Vulnérabilités"),
              Tab(text: "Planification"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _scannerTabController,
            children: [
              // Sous-onglet 1 : Topologie
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.compass, size: 64, color: Color(0xFF00E5FF)),
                    const SizedBox(height: 16),
                    const Text('Cartographie Interactive (Zeek conn.log)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Visualisation des flux Est-Ouest et Nord-Sud de l\'infrastructure.', style: TextStyle(color: Colors.blueGrey[400], fontSize: 12)),
                  ],
                ),
              ),
              // Sous-onglet 2 : Inventaire des Actifs
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _networkAssets.length,
                itemBuilder: (context, index) {
                  final asset = _networkAssets[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kPanelColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                    child: ListTile(
                      leading: Icon(CupertinoIcons.device_laptop, color: kCyan),
                      title: Text(asset['ip']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('MAC: ${asset['mac']} • ${asset['role']}', style: TextStyle(color: Colors.blueGrey[400], fontSize: 11)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.greenAccent)),
                        child: Text(asset['status']!, style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
                      ),
                    ),
                  );
                },
              ),
              // Sous-onglet 3 : Ports & Vulnérabilités (CVE Wazuh)
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: kPanelColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: kRed.withValues(alpha: 0.3))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("CVE-2026-XXXX", style: GoogleFonts.jetBrainsMono(color: kRed, fontWeight: FontWeight.bold)),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: kRed.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)), child: Text("Critique", style: TextStyle(color: kRed, fontSize: 10))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text("Cible : 192.168.1.50 (Serveur Docker)", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text("Vulnérabilité détectée sur l'API Docker non sécurisée.", style: TextStyle(color: Colors.blueGrey[400], fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              // Sous-onglet 4 : Historique & Planification
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Scans Planifiés Automatiques', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: kPanelColor, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                           Icon(CupertinoIcons.clock, color: kCyan),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Scan Complet Infrastructure', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text('Tous les jours à 02:00 AM • Prochain : Demain', style: TextStyle(color: Colors.blueGrey, fontSize: 11)),
                              ],
                            ),
                          ),
                          CupertinoSwitch(value: true, activeTrackColor: kCyan, onChanged: (val) {}),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 5. WAZUH EDR TAB
  // ==========================================
  Widget _buildEdrTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _edrAgents.length,
      itemBuilder: (context, index) {
        final agent = _edrAgents[index];
        bool hasThreats = agent.activeThreats.isNotEmpty;
        Color statusColor = hasThreats ? kRed : Colors.greenAccent;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: kPanelColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
          child: ExpansionTile(
            iconColor: statusColor, collapsedIconColor: statusColor,
            leading: Icon(CupertinoIcons.device_laptop, color: statusColor, size: 28),
            title: Text(agent.hostname, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text("${agent.ip} • ${agent.os}", style: GoogleFonts.jetBrainsMono(color: Colors.blueGrey[400], fontSize: 11)),
            children: [
              const Divider(color: Colors.white12),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: hasThreats
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("DÉTECTION EDR (PROCESSUS SUSPECTS)", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ...agent.activeThreats.map((threat) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.black, border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${threat['name']} (PID: ${threat['pid']})", style: GoogleFonts.jetBrainsMono(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                Text(threat['desc']!, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white),
                            icon: const Icon(CupertinoIcons.ant_fill, size: 14),
                            label: const Text("KILL", style: TextStyle(fontSize: 10)),
                            onPressed: () => _executeEdrKillProcess(agent, threat['pid']!),
                          )
                        ],
                      ),
                    ))
                  ],
                )
                    : const Center(child: Text("Agent EDR : Aucun processus malveillant.", style: TextStyle(color: Colors.greenAccent, fontSize: 12))),
              )
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // 6. THREAT INTEL (CTI) TAB
  // ==========================================
  Widget _buildCtiTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Cyber Threat Intelligence (CTI)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Interrogez les bases pour analyser une IP ou un Hash.", style: TextStyle(color: Colors.blueGrey[400], fontSize: 12)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctiSearchController,
                  style: GoogleFonts.jetBrainsMono(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Entrez une IPv4 ou un Hash SHA-256...", hintStyle: const TextStyle(color: Colors.white30),
                    filled: true, fillColor: kPanelColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(CupertinoIcons.search, color: Color(0xFF00E5FF)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kCyan, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  setState(() { _isCtiSearching = true; _ctiResult = null; });
                  await Future.delayed(const Duration(seconds: 1));
                  setState(() {
                    _isCtiSearching = false;
                    _ctiResult = {
                      "target": _ctiSearchController.text.isEmpty ? "192.168.1.100" : _ctiSearchController.text,
                      "score": "88/100",
                      "reputation": "MALICIOUS",
                      "tags": ["Botnet C2", "Mirai Variant", "DDoS Node"],
                    };
                  });
                },
                child: _isCtiSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Text("ANALYSER", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 32),
          if (_ctiResult != null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: kPanelColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: kRed.withValues(alpha: 0.5))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("RAPPORT CTI", style: TextStyle(color: Colors.blueGrey[300], fontSize: 10, fontWeight: FontWeight.bold)),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: kRed.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)), child: Text(_ctiResult!["reputation"], style: TextStyle(color: kRed, fontSize: 10, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_ctiResult!["target"], style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("Score de Menace : ${_ctiResult!["score"]}", style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            )
        ],
      ),
    );
  }

  // ==========================================
  // 7. RÈGLES NIDS TAB
  // ==========================================
  Widget _buildNidsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _nidsRules.length,
      itemBuilder: (context, index) {
        final rule = _nidsRules[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: kPanelColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.blueGrey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)), child: Text("SID: ${rule.sid}", style: GoogleFonts.jetBrainsMono(color: Colors.blueGrey[300], fontSize: 10))),
                        const SizedBox(width: 8),
                        Text(rule.category, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(rule.description, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Actif", style: TextStyle(color: Colors.blueGrey, fontSize: 10)),
                  CupertinoSwitch(value: rule.isActive, activeTrackColor: Colors.greenAccent, onChanged: (val) => setState(() => rule.isActive = val)),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Drop", style: TextStyle(color: Colors.blueGrey, fontSize: 10)),
                  CupertinoSwitch(value: rule.dropTraffic, activeTrackColor: kRed, onChanged: (val) => setState(() => rule.dropTraffic = val)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // 8. AUDIT ACTIF TAB (Nmap, Tshark)
  // ==========================================
  Widget _buildAuditTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: kPanelColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("OUTILS D'AUDIT SYSTÈME & RÉSEAU", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: "Moteur",
                        value: _selectedTool,
                        items: _toolProfiles.keys.toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedTool = val!;
                            _selectedProfile = _toolProfiles[val]!.keys.first;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        label: "Profil",
                        value: _selectedProfile,
                        items: _toolProfiles[_selectedTool]!.keys.toList(),
                        displayMap: _toolProfiles[_selectedTool],
                        onChanged: (val) => setState(() => _selectedProfile = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Cible (IP / CIDR)", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: const Color(0xFF070B14), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
                  child: TextField(
                    controller: _targetController,
                    style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: kCyan, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        icon: _isAuditing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Icon(CupertinoIcons.play_arrow_solid, size: 16),
                        label: Text(_isAuditing ? "ANALYSE..." : "LANCER L'AUDIT", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: _isAuditing ? null : _runAuditTool,
                      ),
                    ),
                    if (_isAuditing) ...[
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: kRed.withValues(alpha: 0.1), foregroundColor: kRed, side: const BorderSide(color: Color(0xFFFF2A55)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        icon: const Icon(CupertinoIcons.stop_fill, size: 16),
                        label: const Text("KILL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: _stopAuditTool,
                      ),
                    ]
                  ],
                )
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16), border: Border.all(color: kCyan.withValues(alpha: 0.3))),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(_auditConsoleOutput, style: GoogleFonts.jetBrainsMono(color: kCyan, fontSize: 12, height: 1.5)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _runAuditTool() async {
    setState(() {
      _isAuditing = true;
      _auditConsoleOutput = "[SYSTÈME] Initialisation de $_selectedTool sur ${_targetController.text}...\n";
    });

    try {
      final cmdData = AuditCliWrapper.buildCommand(
        toolName: _selectedTool,
        target: _targetController.text.trim(),
        auditProfile: _selectedProfile,
      );

      await _processManager.startTool(
          cmdData['executable'],
          cmdData['arguments'],
              (output) { if (mounted) setState(() => _auditConsoleOutput += "$output\n"); },
              (exitCode) { if (mounted) setState(() { _isAuditing = false; _auditConsoleOutput += "\n[SYSTÈME] Terminé (Code: $exitCode)\n"; }); }
      );
    } catch (e) {
      setState(() { _isAuditing = false; _auditConsoleOutput += "\n❌ Erreur : $e\n"; });
    }
  }

  void _stopAuditTool() {
    _processManager.killActiveProcess();
    setState(() {
      _isAuditing = false;
      _auditConsoleOutput += "\n🛑 Interruption forcée par l'administrateur.\n";
    });
  }

  Widget _buildDropdown({required String label, required String value, required List<String> items, required Function(String?) onChanged, Map<String, String>? displayMap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: const Color(0xFF070B14), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: kPanelColor,
              value: value,
              icon: const Icon(CupertinoIcons.chevron_down, color: Colors.blueGrey, size: 14),
              style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 12),
              items: items.map((String val) => DropdownMenuItem(value: val, child: Text(displayMap != null ? displayMap[val]! : val.toUpperCase(), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}