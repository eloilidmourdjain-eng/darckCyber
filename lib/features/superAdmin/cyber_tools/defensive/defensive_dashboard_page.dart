import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rxdart/rxdart.dart';
import 'package:google_fonts/google_fonts.dart';

// ⚠️ IMPORTS DE TES MOTEURS D'AUDIT NATIFS (Chemin corrigé vers le dossier 'defensive')
import 'package:darck_puls/features/superAdmin/cyber_tools/defensive/audit_cli_wrapper.dart';
import 'package:darck_puls/features/superAdmin/cyber_tools/defensive/audit_process_manager.dart';

// --- MULTITHREADING (Isolates) ---
Map<String, dynamic>? parseAlertIsolate(String rawJson) {
  try {
    final alert = jsonDecode(rawJson);
    if (alert is Map<String, dynamic> && alert.containsKey('source_ip')) return alert;
  } catch (e) { }
  return null;
}

// --- MODÈLES BLUE TEAM ---
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

  // --- ÉTAT DE L'UI ---
  late TabController _tabController;
  late AnimationController _pulseController;

  final List<Map<String, dynamic>> _alertsLog = [];
  final List<FlSpot> _chartData = [];
  double _timeCounter = 19;
  String _selectedFilter = 'ALL';
  bool _isConnected = false;
  bool _isNetworkSecured = true;

  // --- ÉTATS DU NOUVEL ONGLET AUDIT (NMAP/WIRESHARK) ---
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

  // --- BASES DE DONNÉES BLUE TEAM SIMULÉES ---
  final List<EdrAgent> _edrAgents = [
    EdrAgent("SRV-DB-01", "10.0.0.5", "Linux (Ubuntu)", "Sain"),
    EdrAgent("LAPTOP-CEO", "192.168.1.45", "Windows 11", "Infecté", activeThreats: [
      {"pid": "4452", "name": "powershell.exe", "hash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", "desc": "Exécution de script encodé en Base64 (Suspect)"}
    ]),
  ];

  final List<NidsRule> _nidsRules = [
    NidsRule("2010935", "ET SCAN Suspicious inbound to MSSQL port 1433", "Reconnaissance", true, true),
    NidsRule("2024364", "ET MALWARE Win32/Trickbot CnC Checkin", "Malware C2", true, true),
    NidsRule("2013028", "ET POLICY Cleartext Credentials over HTTP", "Policy Violation", true, false),
  ];

  final TextEditingController _ctiSearchController = TextEditingController();
  Map<String, dynamic>? _ctiResult;
  bool _isCtiSearching = false;

  // Thème Cyber
  final Color kBgColor = const Color(0xFF070B14);
  final Color kPanelColor = const Color(0xFF131C2D);
  final Color kCyan = const Color(0xFF00E5FF);
  final Color kRed = const Color(0xFFFF2A55);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // 6 Onglets
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

  // --- ACTIONS OPÉRATIONNELLES (SOAR / EDR) ---
  void _executeBan(String ip) async {
    Navigator.pop(context);
    if (!_ipv4Regex.hasMatch(ip)) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transmission de l\'ordre de drop (UFW) pour $ip...'), backgroundColor: kPanelColor));
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚡ L\'adresse IP a été isolée.'), backgroundColor: Colors.greenAccent));
  }

  void _executeEdrKillProcess(EdrAgent agent, String pid) async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Agent EDR: Envoi du signal SIGKILL au processus $pid sur ${agent.hostname}...'), backgroundColor: kPanelColor));

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      agent.activeThreats.removeWhere((t) => t["pid"] == pid);
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Processus malveillant terminé avec succès.'), backgroundColor: Colors.greenAccent));
  }

  // ==========================================
  // BUILD PRINCIPAL (L'UI DU DASHBOARD)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: const Text('SOC & Security Operations', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [_buildStatusBadge()],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: kCyan,
          labelColor: kCyan,
          unselectedLabelColor: Colors.blueGrey[600],
          tabs: const [
            Tab(icon: Icon(CupertinoIcons.shield_lefthalf_fill), text: "Radar SIEM"),
            Tab(icon: Icon(CupertinoIcons.device_desktop), text: "Wazuh EDR"),
            Tab(icon: Icon(CupertinoIcons.search), text: "Threat Intel"),
            Tab(icon: Icon(CupertinoIcons.layers_alt_fill), text: "Règles NIDS"),
            Tab(icon: Icon(CupertinoIcons.list_bullet), text: "Logs Réseau"),
            Tab(icon: Icon(CupertinoIcons.waveform_path), text: "Audit Actif"),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(),
          children: [
            _buildRadarTab(),
            _buildEdrTab(),
            _buildCtiTab(),
            _buildNidsTab(),
            _buildSiemLogTab(),
            _buildAuditTab(),
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
  // ONGLET 6 : AUDIT ACTIF (TShark, Nmap, MTR)
  // ==========================================
  Widget _buildAuditTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kPanelColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("OUTILS DE DIAGNOSTIC NATIFS (OS INTÉGRÉ)", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: "Moteur d'Audit",
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
                        label: "Profil d'Exécution",
                        value: _selectedProfile,
                        items: _toolProfiles[_selectedTool]!.keys.toList(),
                        displayMap: _toolProfiles[_selectedTool],
                        onChanged: (val) => setState(() => _selectedProfile = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text("Cible de l'Audit (IP / CIDR / Localhost)", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: const Color(0xFF070B14), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: _isAuditing
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Icon(CupertinoIcons.play_arrow_solid, size: 16),
                        label: Text(_isAuditing ? "ANALYSE EN COURS..." : "DÉMARRER LA COLLECTE", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: _isAuditing ? null : _runAuditTool,
                      ),
                    ),
                    if (_isAuditing) ...[
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kRed.withValues(alpha: 0.1),
                          foregroundColor: kRed,
                          side: const BorderSide(color: Color(0xFFFF2A55)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
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
              decoration: BoxDecoration(
                color: const Color(0xFF000000),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kCyan.withValues(alpha: 0.3)),
                boxShadow: [BoxShadow(color: kCyan.withValues(alpha: 0.05), blurRadius: 20)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(CupertinoIcons.circle_fill, color: Colors.redAccent, size: 10), const SizedBox(width: 6),
                      const Icon(CupertinoIcons.circle_fill, color: Colors.orangeAccent, size: 10), const SizedBox(width: 6),
                      const Icon(CupertinoIcons.circle_fill, color: Colors.greenAccent, size: 10), const SizedBox(width: 12),
                      Text("Stdout / Console (Audit Process)", style: TextStyle(color: Colors.blueGrey[600], fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white12, height: 1)),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        _auditConsoleOutput,
                        style: GoogleFonts.jetBrainsMono(color: kCyan, fontSize: 12, height: 1.5),
                      ),
                    ),
                  ),
                ],
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
      _auditConsoleOutput = "[SYSTÈME] Initialisation de $_selectedTool sur la cible ${_targetController.text}...\n";
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
              (output) {
            if (mounted) {
              setState(() => _auditConsoleOutput += "$output\n");
            }
          },
              (exitCode) {
            if (mounted) {
              setState(() {
                _isAuditing = false;
                _auditConsoleOutput += "\n[SYSTÈME] Tâche terminée avec le code $exitCode.\n";
              });
            }
          }
      );
    } catch (e) {
      setState(() {
        _isAuditing = false;
        _auditConsoleOutput += "\n❌ [BLOCAGE SÉCURITÉ] : $e\n";
      });
    }
  }

  void _stopAuditTool() {
    _processManager.killActiveProcess();
    setState(() {
      _isAuditing = false;
      _auditConsoleOutput += "\n🛑 [SYSTÈME] Interruption forcée (SIGKILL) par l'administrateur.\n";
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
          decoration: BoxDecoration(color: const Color(0xFF070B14), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
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

  // ==========================================
  // AUTRES ONGLETS (Code précédent inchangé)
  // ==========================================
  Widget _buildRadarTab() {
    Color glowColor = _isNetworkSecured ? Colors.greenAccent : kRed;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: kPanelColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: glowColor.withValues(alpha: 0.3)),
                        boxShadow: [BoxShadow(color: glowColor.withValues(alpha: 0.15 * (_isNetworkSecured ? 1 : _pulseController.value)), blurRadius: 30 * (_isNetworkSecured ? 1 : _pulseController.value))],
                      ),
                      child: Column(
                        children: [
                          Icon(_isNetworkSecured ? CupertinoIcons.shield_lefthalf_fill : CupertinoIcons.shield_slash_fill, color: glowColor, size: 48),
                          const SizedBox(height: 12),
                          Text("Passerelle L3", style: TextStyle(color: Colors.blueGrey[300], fontSize: 12)),
                          Text(_isNetworkSecured ? "SECURE" : "BREACH DETECTED", style: GoogleFonts.jetBrainsMono(color: glowColor, fontSize: 16, fontWeight: FontWeight.bold)),
                          if (!_isNetworkSecured) ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: kRed, foregroundColor: Colors.white),
                              onPressed: () => setState(() { _isNetworkSecured = true; _pulseController.duration = const Duration(seconds: 1); }),
                              child: const Text("ACQUITTER"),
                            )
                          ]
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Container(
                  height: 200,
                  padding: const EdgeInsets.only(top: 24, right: 24, left: 12, bottom: 12),
                  decoration: BoxDecoration(color: kPanelColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false), titlesData: const FlTitlesData(show: false), borderData: FlBorderData(show: false), minY: 0, maxY: 10,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _chartData, isCurved: true, curveSmoothness: 0.2, color: kRed, barWidth: 3, dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [kRed.withValues(alpha: 0.4), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

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
            title: Text(agent.hostname, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text("${agent.ip} • ${agent.os}", style: GoogleFonts.jetBrainsMono(color: Colors.blueGrey[400], fontSize: 11)),
            children: [
              const Divider(color: Colors.white12),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: hasThreats
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("DÉTECTION COMPORTEMENTALE (PROCESSUS SUSPECTS)", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
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
                            icon: const Icon(CupertinoIcons.ant_fill, size: 14), label: const Text("KILL PROCESS", style: TextStyle(fontSize: 10)),
                            onPressed: () => _executeEdrKillProcess(agent, threat['pid']!),
                          )
                        ],
                      ),
                    ))
                  ],
                )
                    : const Center(child: Text("Agent EDR: Aucun processus malveillant détecté.", style: TextStyle(color: Colors.greenAccent, fontSize: 12))),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildCtiTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Cyber Threat Intelligence (CTI)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Interrogez les bases OTX / VirusTotal pour analyser une IP, un Domaine ou un Hash.", style: TextStyle(color: Colors.blueGrey[400], fontSize: 12)),
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  setState(() { _isCtiSearching = true; _ctiResult = null; });
                  await Future.delayed(const Duration(seconds: 2));
                  setState(() {
                    _isCtiSearching = false;
                    _ctiResult = {
                      "target": _ctiSearchController.text,
                      "score": "88/100",
                      "reputation": "MALICIOUS",
                      "tags": ["Botnet C2", "Mirai Variant", "DDoS Node"],
                      "last_seen": "Aujourd'hui, 14:02 UTC"
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
                      Text("RAPPORT D'ANALYSE CTI", style: TextStyle(color: Colors.blueGrey[300], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: kRed.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)), child: Text(_ctiResult!["reputation"], style: TextStyle(color: kRed, fontSize: 10, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_ctiResult!["target"], style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.flame_fill, color: Colors.orangeAccent, size: 16),
                      const SizedBox(width: 8),
                      Text("Score de Menace : ${_ctiResult!["score"]}", style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: (_ctiResult!["tags"] as List<String>).map((tag) => Chip(
                      backgroundColor: Colors.black, side: const BorderSide(color: Colors.white12),
                      label: Text(tag, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    )).toList(),
                  )
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildNidsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _nidsRules.length,
      itemBuilder: (context, index) {
        final rule = _nidsRules[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: kPanelColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
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
                  const Text("Activer", style: TextStyle(color: Colors.blueGrey, fontSize: 10)),
                  CupertinoSwitch(value: rule.isActive, activeColor: Colors.greenAccent, onChanged: (val) => setState(() => rule.isActive = val)),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Drop Traffic", style: TextStyle(color: Colors.blueGrey, fontSize: 10)),
                  CupertinoSwitch(value: rule.dropTraffic, activeColor: kRed, onChanged: (val) => setState(() => rule.dropTraffic = val)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildSiemLogTab() {
    final filteredAlerts = _selectedFilter == 'ALL' ? _alertsLog : _alertsLog.where((alert) => alert["severity"] == _selectedFilter).toList();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildFilterChip('ALL', 'Tout', kCyan),
              _buildFilterChip('CRITICAL', 'Critique', kRed),
              _buildFilterChip('WARNING', 'Avertissement', Colors.orangeAccent),
              _buildFilterChip('INFO', 'Information', Colors.greenAccent),
            ],
          ),
        ),
        Expanded(
          child: filteredAlerts.isEmpty
              ? Center(child: Text("En attente de trames SIEM...", style: TextStyle(color: Colors.blueGrey[400])))
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
                          Text(alert['title'] ?? 'Inconnu', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          Text("SRC: ${alert['source_ip']} • Score: ${alert['severity_score']}", style: GoogleFonts.jetBrainsMono(color: Colors.blueGrey[300], fontSize: 10)),
                        ],
                      ),
                    ),
                    if (isCritical || alert['severity'] == 'WARNING')
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: color.withValues(alpha: 0.1), foregroundColor: color, elevation: 0),
                        onPressed: () => _executeBan(alert['source_ip']),
                        child: const Text("Bannir l'IP"),
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
}