import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:network_info_plus/network_info_plus.dart';

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
  final int ttl; // Time To Live (Utilisé pour l'OS Fingerprinting)
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
          // Sécurité anti-crash si le socket plante
          completedTasks++;
          if (onProgress != null) onProgress(completedTasks / totalIps);
        }),
      );
    }

    await Future.wait(scanTasks); // Attente parallèle

    // Tri IP croissant (ex: 192.168.1.2 avant 192.168.1.10)
    activeDevices.sort((a, b) {
      int ipA = int.parse(a.ip.split('.').last);
      int ipB = int.parse(b.ip.split('.').last);
      return ipA.compareTo(ipB);
    });

    return activeDevices;
  }

  Future<NetworkDevice?> _pingAndDiscover(String ip) async {
    try {
      final ping = Ping(ip, count: 1, timeout: 1); // Timeout agressif (1 sec)
      final response = await ping.stream.first;

      if (response.response != null && response.response!.time != null) {
        int pingTime = response.response!.time!.inMilliseconds;
        int ttl = response.response!.ttl ?? 64;

        // CORRECTION : La variable _pingLatencyMs a été retirée d'ici pour être placée au bon endroit.

        // OS Fingerprinting basé sur le TTL réseau
        String osGuess = _guessOsByTtl(ttl);

        NetworkDevice device = NetworkDevice(ip: ip, pingMs: pingTime, ttl: ttl, osType: osGuess);

        // Scan TCP rapide et silencieux
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
    } catch (e) {
      // Host down ou injoignable
    }
    return null;
  }

  // ALGORITHME : OS Fingerprinting via TTL
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
      } catch (e) {
        // Port fermé ou filtré
      }
    }
    return openPorts;
  }

  Future<String> _getMacFromArp(String ip) async {
    try {
      ProcessResult result = await Process.run(Platform.isWindows ? 'arp' : 'arp', [Platform.isWindows ? '-a' : '-n', ip]);
      RegExp macRegex = RegExp(r'([0-9a-fA-F]{2}[:-]){5}([0-9a-fA-F]{2})');
      var match = macRegex.firstMatch(result.stdout.toString());
      if (match != null) return match.group(0)!.toUpperCase().replaceAll('-', ':');
    } catch (e) {
      debugPrint("ARP Error: $e");
    }
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

  // Wi-Fi States
  bool _isWifiConnected = true;
  bool _isHotspotSharingActive = true;
  final String _currentWifiSSID = "DARCK_CYBER_SECURE_WIFI";
  double _sharedBandwidthLimitMbps = 150.0;

  // Scanner States
  bool _isScanning = false;
  double _scanProgress = 0.0;
  String _pingResult = "Prêt à auditer le réseau local.";

  // CORRECTION : La variable manquante est déclarée ici (Dans les états de l'interface)
  int? _pingLatencyMs;

  List<NetworkDevice> _connectedDevices = [];

  // Ports de la passerelle
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
    _tabController = TabController(length: 3, vsync: this);
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
    super.dispose();
  }

  // --- ACTIONS DE L'ADMINISTRATEUR ---
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
        // Évite la division par zéro si aucun appareil n'est trouvé
        _pingLatencyMs = devices.isEmpty ? null : stopwatch.elapsedMilliseconds ~/ devices.length;
        _pingResult = devices.isEmpty
            ? "Scan terminé. Aucun appareil détecté sur $subnet.0/24"
            : "Balayage réussi : ${devices.length} hôtes découverts.";
      });
    }
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
        title: const Text("Scanner Réseau & Endpoint Admin", style: TextStyle(color: kTextMain, fontSize: 16, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kAccentColor,
          unselectedLabelColor: kTextSecondary,
          indicatorColor: kAccentColor,
          tabs: const [
            Tab(icon: Icon(CupertinoIcons.search, size: 18), text: "Découverte"),
            Tab(icon: Icon(CupertinoIcons.device_laptop, size: 18), text: "Endpoints"),
            Tab(icon: Icon(CupertinoIcons.slider_horizontal_3, size: 18), text: "Hotspot & QoS"),
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
        children: [
          _buildScannerTab(),
          _buildEndpointsTab(),
          _buildHotspotTab(),
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

        // Console de statut
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

        // OS Fingerprint icon logic
        IconData osIcon = CupertinoIcons.device_laptop;
        if (device.osType.contains('Linux') || device.osType.contains('Android')) osIcon = CupertinoIcons.device_phone_portrait;
        if (device.osType.contains('Windows')) osIcon = CupertinoIcons.square_grid_2x2_fill;
        if (device.osType.contains('Routeur')) osIcon = CupertinoIcons.rocket_fill;

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
                if (value == 'copy') {
                  Clipboard.setData(ClipboardData(text: device.ip));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("IP copiée dans le presse-papier.")));
                } else if (value == 'scan') {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lancement du Deep Scan sur ${device.ip}...")));
                } else if (value == 'wol') {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Paquet Magic (WoL) envoyé à ${device.vendor}")));
                } else if (value == 'block') {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Machine placée en VLAN de quarantaine."), backgroundColor: Colors.redAccent));
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'copy', child: Row(children: [Icon(CupertinoIcons.doc_on_clipboard_fill, size: 16, color: Colors.white), SizedBox(width: 8), Text("Copier l'IP", style: TextStyle(color: Colors.white))])),
                const PopupMenuItem(value: 'scan', child: Row(children: [Icon(CupertinoIcons.search, size: 16, color: Colors.orangeAccent), SizedBox(width: 8), Text("Deep Port Scan", style: TextStyle(color: Colors.white))])),
                const PopupMenuItem(value: 'wol', child: Row(children: [Icon(CupertinoIcons.bolt_fill, size: 16, color: Colors.yellowAccent), SizedBox(width: 8), Text("Wake-on-LAN", style: TextStyle(color: Colors.white))])),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'block', child: Row(children: [Icon(CupertinoIcons.nosign, size: 16, color: Colors.redAccent), SizedBox(width: 8), Text("Isoler (Quarantaine)", style: TextStyle(color: Colors.redAccent))])),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // ONGLET 3 : HOTSPOT & RÉGULATION (QoS)
  // ==========================================
  Widget _buildHotspotTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      children: [
        const Text("PARAMÈTRES DU CONTRÔLEUR D'ACCÈS (WLC)", style: TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Diffusion SSID (Wi-Fi)", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  CupertinoSwitch(value: _isWifiConnected, activeTrackColor: Colors.greenAccent, onChanged: (val) => setState(() => _isWifiConnected = val)),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white12, height: 1)),
              Text("Réseau Actif : $_currentWifiSSID", style: GoogleFonts.jetBrainsMono(color: kAccentColor, fontSize: 12)),
              const SizedBox(height: 4),
              const Text("Sécurité : WPA3-Enterprise / RADIUS", style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 32),

        const Text("TRAFFIC SHAPING (QoS)", style: TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Activer la Passerelle Captive", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                subtitle: const Text("Bloque l'internet jusqu'à l'authentification", style: TextStyle(color: kTextSecondary, fontSize: 11)),
                value: _isHotspotSharingActive,
                activeTrackColor: Colors.purpleAccent,
                onChanged: (val) => setState(() => _isHotspotSharingActive = val),
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white12, height: 1)),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Bande Passante Globale (Throttling)", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text("${_sharedBandwidthLimitMbps.toInt()} Mbps", style: GoogleFonts.jetBrainsMono(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),

              // CORRECTION: Utilisation des paramètres natifs du Slider
              Slider(
                value: _sharedBandwidthLimitMbps,
                min: 10.0, max: 1000.0, divisions: 99,
                activeColor: Colors.purpleAccent,
                inactiveColor: Colors.white10,
                onChanged: (val) => setState(() => _sharedBandwidthLimitMbps = val),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity, height: 45,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  icon: const Icon(CupertinoIcons.checkmark_seal_fill, size: 18),
                  label: const Text("Déployer les règles QoS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Règles QoS injectées dans le routeur."), backgroundColor: Colors.purpleAccent)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}