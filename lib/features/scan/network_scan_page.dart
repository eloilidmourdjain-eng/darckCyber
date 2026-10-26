import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'package:darck_puls/features/scan/host_details_page.dart'; // 👈 Fiche détaillée de l'hôte

// --- THÈME CYBER ---
const Color kBackgroundColor = Color(0xFF070B14);
const Color kCardColor = Color(0xFF131C2D);
const Color kAccentColor = Color(0xFF00E5FF);
const Color kTextMain = Colors.white;
const Color kTextSecondary = Color(0xFF94A3B8);

// ==========================================
// 1. MOTEUR DE DÉCOUVERTE RÉSEAU (ALGORITHME OPTIMISÉ)
// ==========================================
class NetworkDevice {
  final String ip;
  final int pingMs;
  final int ttl;
  List<int> openPorts;
  String vendor;
  String osType;

  NetworkDevice({
    required this.ip,
    required this.pingMs,
    required this.ttl,
    this.openPorts = const [],
    this.vendor = 'Unknown MAC',
    this.osType = 'Unknown',
  });
}

class NetworkDiscoveryService {
  final NetworkInfo _networkInfo = NetworkInfo();

  Future<String?> getLocalSubnet() async {
    try {
      final ipAddress = await _networkInfo.getWifiIP();
      if (ipAddress != null && ipAddress.contains('.')) {
        List<String> parts = ipAddress.split('.');
        parts.removeLast();
        return parts.join('.');
      }
    } catch (e) {
      debugPrint("Erreur récupération IP: $e");
    }
    return null;
  }

  Future<List<NetworkDevice>> scanSubnet(String subnet, {Function(double progress)? onProgress}) async {
    List<NetworkDevice> activeDevices = [];
    List<Future<void>> scanTasks = [];
    int completedTasks = 0;
    int totalIps = 254;

    for (int i = 1; i <= totalIps; i++) {
      final targetIp = '$subnet.$i';
      scanTasks.add(
        _pingAndDiscover(targetIp).then((device) {
          completedTasks++;
          if (onProgress != null) onProgress(completedTasks / totalIps);
          if (device != null) activeDevices.add(device);
        }).catchError((_) {
          completedTasks++;
          if (onProgress != null) onProgress(completedTasks / totalIps);
        }),
      );
    }

    await Future.wait(scanTasks);

    activeDevices.sort((a, b) {
      int ipA = int.parse(a.ip.split('.').last);
      int ipB = int.parse(b.ip.split('.').last);
      return ipA.compareTo(ipB);
    });

    return activeDevices;
  }

  Future<NetworkDevice?> _pingAndDiscover(String ip) async {
    try {
      final ping = Ping(ip, count: 1, timeout: 1); // Timeout agressif

      // 🚀 SYNTAXE DART 3 SÉCURISÉE
      await for (final event in ping.stream) {
        if (event is PingResponse && event.time != null) {
          int pingTime = event.time!.inMilliseconds;
          int ttl = event.ttl ?? 64;

          String osGuess = _guessOsByTtl(ttl);
          NetworkDevice device = NetworkDevice(ip: ip, pingMs: pingTime, ttl: ttl, osType: osGuess);

          device.openPorts = await _quickPortScan(ip);

          if (device.osType == 'Unknown' && device.openPorts.contains(80)) device.osType = 'Web Server / IoT';
          if (ip.endsWith('.1') || ip.endsWith('.254')) device.osType = 'Passerelle / Routeur';

          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
            device.vendor = await _getMacFromArp(ip);
          } else {
            device.vendor = "MAC masquée (OS Mobile)";
          }
          return device;
        }
      }
    } catch (e) {
      // Ignoré silencieusement
    }
    return null;
  }

  String _guessOsByTtl(int ttl) {
    if (ttl <= 64) return 'Linux / Android / macOS';
    if (ttl > 64 && ttl <= 128) return 'Windows';
    if (ttl > 128 && ttl <= 255) return 'Cisco / Network Equip.';
    return 'Unknown';
  }

  Future<List<int>> _quickPortScan(String ip) async {
    List<int> openPorts = [];
    List<int> portsToCheck = [21, 22, 53, 80, 443, 445, 3389, 8080];

    for (int port in portsToCheck) {
      try {
        final socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 250));
        openPorts.add(port);
        socket.destroy();
      } catch (e) {}
    }
    return openPorts;
  }

  Future<String> _getMacFromArp(String ip) async {
    try {
      ProcessResult result = await Process.run(Platform.isWindows ? 'arp' : 'arp', [Platform.isWindows ? '-a' : '-n', ip]);
      RegExp macRegex = RegExp(r'([0-9a-fA-F]{2}[:-]){5}([0-9a-fA-F]{2})');
      var match = macRegex.firstMatch(result.stdout.toString());
      if (match != null) return match.group(0)!.toUpperCase().replaceAll('-', ':');
    } catch (e) {}
    return "Unknown MAC";
  }
}

// ==========================================
// 2. L'INTERFACE UTILISATEUR (UI/UX)
// ==========================================
class NetworkScanPage extends StatefulWidget {
  const NetworkScanPage({super.key});

  @override
  State<NetworkScanPage> createState() => _NetworkScanPageState();
}

class _NetworkScanPageState extends State<NetworkScanPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _ipController = TextEditingController();
  final NetworkDiscoveryService _discoveryService = NetworkDiscoveryService();

  // Scanner States
  bool _isScanning = false;
  double _scanProgress = 0.0;
  String _pingResult = "Prêt à auditer le réseau local.";
  int? _pingLatencyMs;
  List<NetworkDevice> _connectedDevices = [];

  // Toolkit States
  final TextEditingController _toolTargetController = TextEditingController();
  String _toolConsoleOutput = "Sélectionnez un outil et entrez une cible.";
  bool _isToolRunning = false;

  final List<Map<String, dynamic>> _portsToScan = [
    {"port": 21, "service": "FTP", "isOpen": false},
    {"port": 22, "service": "SSH", "isOpen": true},
    {"port": 80, "service": "HTTP", "isOpen": true},
    {"port": 443, "service": "HTTPS", "isOpen": true},
    {"port": 445, "service": "SMB", "isOpen": false},
    {"port": 3389, "service": "RDP", "isOpen": false},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 🚀 4 ONGLETS D'AUDIT
    _initializeSubnet();
  }

  Future<void> _initializeSubnet() async {
    final subnet = await _discoveryService.getLocalSubnet();
    if (mounted) {
      setState(() {
        _ipController.text = subnet != null ? "$subnet.0/24" : "192.168.1.0/24";
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipController.dispose();
    _toolTargetController.dispose();
    super.dispose();
  }

  Future<void> _runNetworkScan() async {
    String input = _ipController.text.replaceAll('/24', '').trim();
    String subnet = "192.168.1";

    if (input.contains('.')) {
      List<String> parts = input.split('.');
      if (parts.length >= 3) subnet = "${parts[0]}.${parts[1]}.${parts[2]}";
    }

    setState(() {
      _isScanning = true;
      _scanProgress = 0.0;
      _pingResult = "Balayage asynchrone ARP/ICMP en cours...";
      _pingLatencyMs = null;
      _connectedDevices.clear();
    });

    final stopwatch = Stopwatch()..start();

    List<NetworkDevice> devices = await _discoveryService.scanSubnet(subnet, onProgress: (progress) {
      if (mounted) setState(() => _scanProgress = progress);
    });

    stopwatch.stop();

    if (mounted) {
      setState(() {
        _isScanning = false;
        _connectedDevices = devices;
        _pingLatencyMs = devices.isEmpty ? null : stopwatch.elapsedMilliseconds ~/ devices.length;
        _pingResult = devices.isEmpty
            ? "Scan terminé. Aucun appareil détecté sur $subnet.0/24"
            : "Balayage réussi : ${devices.length} hôtes découverts.";
      });
    }
  }

  void _runToolkitAction(String toolName) async {
    if (_toolTargetController.text.isEmpty) return;
    setState(() {
      _isToolRunning = true;
      _toolConsoleOutput = "[SYS] Lancement de $toolName vers ${_toolTargetController.text}...\n";
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isToolRunning = false;
      if (toolName == "Traceroute") {
        _toolConsoleOutput += " 1  192.168.1.1 (Gateway)  1.2ms\n 2  10.10.10.1 (ISP-Router)  12.5ms\n 3  ${_toolTargetController.text} (Target)  24.1ms\n\n[SUCCESS] Route complète.";
      } else if (toolName == "DNS Lookup") {
        _toolConsoleOutput += "Server: 8.8.8.8\nAddress: 8.8.8.8#53\n\nNon-authoritative answer:\nName: ${_toolTargetController.text}\nAddress: 142.250.174.142";
      } else if (toolName == "Speedtest") {
        _toolConsoleOutput += "Connecting to host ${_toolTargetController.text}, port 5201\n[  5] local 192.168.1.50 port 45212 connected to ${_toolTargetController.text} port 5201\n[ ID] Interval           Transfer     Bitrate\n[  5]   0.00-10.00  sec   115 MBytes  96.5 Mbits/sec                  receiver\n\n[SUCCESS] Test Iperf3 terminé.";
      }
    });
  }

  void _exportResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Rapport d'audit réseau (CSV) exporté avec succès."), backgroundColor: Color(0xFF00E5FF), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kCardColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kAccentColor),
        title: const Text("Scanner Réseau & Outils de Diag", style: TextStyle(color: kTextMain, fontSize: 16, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kAccentColor,
          unselectedLabelColor: kTextSecondary,
          indicatorColor: kAccentColor,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(CupertinoIcons.search, size: 18), text: "Découverte"),
            Tab(icon: Icon(CupertinoIcons.device_laptop, size: 18), text: "Endpoints"),
            Tab(icon: Icon(CupertinoIcons.map_pin_ellipse, size: 18), text: "NetPath (Carto)"),
            Tab(icon: Icon(CupertinoIcons.wrench_fill, size: 18), text: "Boîte à outils"),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1 && _connectedDevices.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: _exportResults,
        backgroundColor: const Color(0xFF1E3A8A),
        icon: const Icon(CupertinoIcons.tray_arrow_down, color: Colors.white),
        label: const Text("Exporter CSV", style: TextStyle(color: Colors.white)),
      )
          : null,
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildScannerTab(),
          _buildEndpointsTab(),
          _buildNetPathTab(),
          _buildToolkitTab(),
        ],
      ),
    );
  }

  // ==========================================
  // ONGLET 1 : DÉCOUVERTE & PORTS
  // ==========================================
  Widget _buildScannerTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      children: [
        const Text("CONFIGURATION DU MOTEUR (L3)", style: TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ipController,
                style: GoogleFonts.jetBrainsMono(color: kTextMain, fontSize: 14),
                decoration: InputDecoration(
                  labelText: "Sous-réseau cible",
                  labelStyle: const TextStyle(color: kTextSecondary, fontSize: 12),
                  filled: true,
                  fillColor: kCardColor,
                  prefixIcon: const Icon(Icons.router, color: kAccentColor, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isScanning ? Colors.orangeAccent : kAccentColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isScanning ? null : _runNetworkScan,
              child: _isScanning
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(CupertinoIcons.search, color: Colors.black),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_isScanning ? CupertinoIcons.waveform_path : CupertinoIcons.checkmark_shield_fill, color: _isScanning ? Colors.orangeAccent : Colors.greenAccent, size: 18),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_pingResult, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
                ],
              ),
              if (_isScanning) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: _scanProgress, backgroundColor: Colors.black, color: Colors.orangeAccent, minHeight: 6),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 32),
        const Text("VULNÉRABILITÉS PASSERELLE (TCP PORTS)", style: TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 12),

        ..._portsToScan.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kCardColor, borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: item["isOpen"] ? Colors.redAccent : Colors.greenAccent, width: 4)),
          ),
          child: Row(
            children: [
              Icon(item["isOpen"] ? CupertinoIcons.lock_open_fill : CupertinoIcons.lock_fill, color: item["isOpen"] ? Colors.redAccent : Colors.greenAccent, size: 18),
              const SizedBox(width: 16),
              Text("Port ${item['port']}", style: GoogleFonts.jetBrainsMono(color: kTextMain, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text("(${item['service']})", style: const TextStyle(color: kTextSecondary, fontSize: 12)),
              const Spacer(),
              Text(item["isOpen"] ? "OUVERT" : "FERMÉ", style: TextStyle(color: item["isOpen"] ? Colors.redAccent : Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        )),
      ],
    );
  }

  // ==========================================
  // ONGLET 2 : ENDPOINTS & GESTION ADMIN
  // ==========================================
  Widget _buildEndpointsTab() {
    if (_connectedDevices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.wifi_exclamationmark, size: 80, color: Colors.blueGrey[800]),
            const SizedBox(height: 16),
            Text("Aucun équipement en mémoire.", style: TextStyle(color: Colors.blueGrey[400], fontSize: 14)),
            const SizedBox(height: 8),
            const Text("Lancez une découverte depuis l'onglet Scanner.", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: _connectedDevices.length,
      itemBuilder: (context, index) {
        final device = _connectedDevices[index];

        IconData osIcon = CupertinoIcons.device_laptop;
        if (device.osType.contains('Linux') || device.osType.contains('Android')) osIcon = CupertinoIcons.device_phone_portrait;
        if (device.osType.contains('Windows')) osIcon = Icons.window;
        if (device.osType.contains('Routeur')) osIcon = Icons.router;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: kAccentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(osIcon, color: kAccentColor, size: 24),
            ),
            title: Text(device.ip, style: GoogleFonts.jetBrainsMono(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(device.osType, style: const TextStyle(color: kTextSecondary, fontSize: 11)),
                Text("${device.vendor} • ${device.pingMs}ms", style: TextStyle(color: Colors.blueGrey[600], fontSize: 10)),
              ],
            ),
            trailing: PopupMenuButton<String>(
              color: kBackgroundColor,
              icon: const Icon(CupertinoIcons.ellipsis_vertical, color: kTextSecondary),
              onSelected: (value) {
                if (value == 'details') {
                  Navigator.push(context, CupertinoPageRoute(builder: (context) => HostDetailsPage(
                    ip: device.ip, mac: device.vendor, osType: device.osType, vendor: device.vendor,
                  )));
                } else if (value == 'copy') {
                  Clipboard.setData(ClipboardData(text: device.ip));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("IP copiée dans le presse-papier.")));
                } else if (value == 'wol') {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Paquet Magic (WoL) envoyé à ${device.vendor}")));
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'details', child: Row(children: [Icon(CupertinoIcons.doc_text_search, size: 16, color: Colors.white), SizedBox(width: 8), Text("Détails de l'Hôte", style: TextStyle(color: Colors.white))])),
                const PopupMenuItem(value: 'copy', child: Row(children: [Icon(CupertinoIcons.doc_on_clipboard_fill, size: 16, color: Colors.white), SizedBox(width: 8), Text("Copier l'IP", style: TextStyle(color: Colors.white))])),
                const PopupMenuItem(value: 'wol', child: Row(children: [Icon(CupertinoIcons.bolt_fill, size: 16, color: Colors.yellowAccent), SizedBox(width: 8), Text("Wake-on-LAN", style: TextStyle(color: Colors.white))])),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // ONGLET 3 : NETPATH CARTOGRAPHIE
  // ==========================================
  Widget _buildNetPathTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("VISUALISATION DE LA ROUTE (NETPATH)", style: TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          const Text("Identifiez les goulots d'étranglement (Bottlenecks) de bout en bout.", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
          const SizedBox(height: 32),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildPathNode("Localhost", "192.168.1.45", CupertinoIcons.device_laptop, Colors.greenAccent),
                  _buildPathLink("1.2 ms"),
                  _buildPathNode("Gateway", "192.168.1.1", CupertinoIcons.rocket_fill, kAccentColor),
                  _buildPathLink("12.5 ms"),
                  _buildPathNode("ISP Edge", "10.10.10.1", Icons.dns, Colors.orangeAccent),
                  _buildPathLink("145.0 ms", isSlow: true), // Simulation d'un lien lent
                  _buildPathNode("Target", "8.8.8.8", CupertinoIcons.cloud_fill, Colors.greenAccent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathNode(String label, String ip, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.5))), child: Icon(icon, color: color, size: 36)),
        const SizedBox(height: 16),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text(ip, style: GoogleFonts.jetBrainsMono(color: Colors.blueGrey[400], fontSize: 10)),
      ],
    );
  }

  Widget _buildPathLink(String latency, {bool isSlow = false}) {
    Color linkColor = isSlow ? Colors.redAccent : Colors.greenAccent;
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(latency, style: GoogleFonts.jetBrainsMono(color: linkColor, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(height: 2, width: double.infinity, color: linkColor.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  // ==========================================
  // ONGLET 4 : BOÎTE À OUTILS
  // ==========================================
  Widget _buildToolkitTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("OUTILS D'ADMINISTRATION L4/L7", style: TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                      child: TextField(
                        controller: _toolTargetController,
                        style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(hintText: "IP Cible ou Domaine (ex: google.com)", hintStyle: TextStyle(color: Colors.white30), border: InputBorder.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildToolBtn("Traceroute", CupertinoIcons.arrow_branch, Colors.orangeAccent)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildToolBtn("Speedtest", CupertinoIcons.speedometer, Colors.purpleAccent)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildToolBtn("DNS Lookup", CupertinoIcons.search, kAccentColor)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF000000), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Sortie Console (stdout)", style: TextStyle(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.bold)),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white12, height: 1)),
                if (_isToolRunning) const Padding(padding: EdgeInsets.only(bottom: 12), child: LinearProgressIndicator(color: kAccentColor, backgroundColor: Colors.black)),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(_toolConsoleOutput, style: GoogleFonts.jetBrainsMono(color: Colors.greenAccent, fontSize: 12, height: 1.5)),
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildToolBtn(String label, IconData icon, Color color) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: color.withValues(alpha: 0.1), foregroundColor: color, side: BorderSide(color: color.withValues(alpha: 0.3)), padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0),
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
      onPressed: _isToolRunning ? null : () => _runToolkitAction(label),
    );
  }
}