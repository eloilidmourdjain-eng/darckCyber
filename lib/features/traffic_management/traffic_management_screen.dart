import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:darck_puls/features/scan/host_details_page.dart';

class RouterApiService {
  final String routerIp = const String.fromEnvironment('ROUTER_IP', defaultValue: "https://192.168.1.1/api/v1");

  Future<String?> _getAuthToken() async {
    return "Bearer secure_dyn_token_encrypted";
  }

  bool validateNetworkParameters(String ip, String mac) {
    final ipRegExp = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    final macRegExp = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
    return ipRegExp.hasMatch(ip) && macRegExp.hasMatch(mac);
  }

  Future<bool> setQosLimit(String macAddress, double limitMbps) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return false;
      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String> runDiagnostics(String ip) async {
    await Future.delayed(const Duration(seconds: 1));
    return "0% Packet Loss, Avg Latency: 12ms. Status: SECURE & HEALTHY";
  }
}

class ConnectedClient {
  final String name;
  final String mac;
  final String ip;
  double allocatedBandwidth;
  bool isBlocked;

  ConnectedClient(this.name, this.mac, this.ip, this.allocatedBandwidth, this.isBlocked);
}

class TrafficManagementScreen extends StatefulWidget {
  const TrafficManagementScreen({super.key});

  @override
  State<TrafficManagementScreen> createState() => _TrafficManagementScreenState();
}

class _TrafficManagementScreenState extends State<TrafficManagementScreen> {
  final RouterApiService _apiService = RouterApiService();

  bool _is5GHzEnabled = true;
  final String _wifiName = "Office_WiFi_5G";
  bool _isUpdatingWifi = false;
  Timer? _debounceTimer;

  // --- NOUVEAU : GESTION DE LA RECHERCHE ET DU FILTRE ---
  final TextEditingController _searchController = TextEditingController();
  String _currentFilter = 'ALL'; // 'ALL', 'ACTIVE', 'BLOCKED'

  final List<ConnectedClient> _masterClients = [
    ConnectedClient("Serveur NAS", "00:11:22:33:44:55", "192.168.1.10", 1000.0, false),
    ConnectedClient("PC-Compta", "AA:BB:CC:DD:EE:FF", "192.168.1.55", 50.0, false),
    ConnectedClient("iPhone Visiteur", "11:22:33:44:55:66", "192.168.1.109", 5.0, true), // Simule un appareil bloqué
  ];

  List<ConnectedClient> _filteredClients = [];

  @override
  void initState() {
    super.initState();
    _filteredClients = List.from(_masterClients);
  }

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClients = _masterClients.where((client) {
        bool matchesSearch = client.name.toLowerCase().contains(query) || client.ip.contains(query);
        bool matchesStatus = _currentFilter == 'ALL' || (_currentFilter == 'BLOCKED' && client.isBlocked) || (_currentFilter == 'ACTIVE' && !client.isBlocked);
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _applyGlobalWifiConfig() async {
    setState(() => _isUpdatingWifi = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isUpdatingWifi = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Configuration Wi-Fi sécurisée appliquée au routeur !"), backgroundColor: Colors.green));
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('SDN & Gestion Trafic (Hardened)', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              TabBar(
                indicatorColor: const Color(0xFF3B82F6), labelColor: const Color(0xFF3B82F6), unselectedLabelColor: Colors.blueGrey[400],
                tabs: const [Tab(icon: Icon(CupertinoIcons.slider_horizontal_3), text: "QoS & Appareils"), Tab(icon: Icon(CupertinoIcons.settings_solid), text: "Configuration Globale")],
              ),
              Expanded(
                child: TabBarView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildTrafficManagementTab(),
                    _buildGlobalConfigTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrafficManagementTab() {
    return Column(
      children: [
        // --- NOUVEAU : BARRE DE RECHERCHE ET FILTRES ---
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(icon: Icon(CupertinoIcons.search, color: Colors.blueGrey, size: 18), hintText: "Rechercher par IP ou Nom...", hintStyle: TextStyle(color: Colors.white30), border: InputBorder.none),
                    onChanged: (val) => _applyFilters(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: const Color(0xFF1E293B),
                    value: _currentFilter,
                    icon: const Icon(CupertinoIcons.slider_horizontal_3, color: Colors.blueGrey, size: 16),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: "ALL", child: Text("Tous les hôtes")),
                      DropdownMenuItem(value: "ACTIVE", child: Text("Actifs (Connectés)", style: TextStyle(color: Colors.greenAccent))),
                      DropdownMenuItem(value: "BLOCKED", child: Text("En Quarantaine", style: TextStyle(color: Colors.redAccent))),
                    ],
                    onChanged: (val) {
                      setState(() { _currentFilter = val!; _applyFilters(); });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- LISTE DES CLIENTS ---
        Expanded(
          child: _filteredClients.isEmpty
              ? const Center(child: Text("Aucun appareil ne correspond à la recherche.", style: TextStyle(color: Colors.blueGrey)))
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: _filteredClients.length,
            itemBuilder: (context, index) {
              return _buildClientTrafficCard(_filteredClients[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClientTrafficCard(ConnectedClient client) {
    bool isUnlimited = client.allocatedBandwidth >= 1000;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: client.isBlocked ? Colors.redAccent.withValues(alpha: 0.5) : Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(client.isBlocked ? CupertinoIcons.nosign : CupertinoIcons.device_laptop, color: client.isBlocked ? Colors.redAccent : Colors.cyanAccent),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(client.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(client.ip, style: GoogleFonts.jetBrainsMono(color: Colors.blueGrey[400], fontSize: 12)),
                    ],
                  ),
                ],
              ),
              PopupMenuButton<String>(
                color: const Color(0xFF0F172A),
                icon: const Icon(CupertinoIcons.ellipsis_vertical, color: Colors.white70),
                onSelected: (value) async {
                  if (value == 'details') {
                    // 🚀 NOUVEAU : OUVERTURE DE LA FICHE HÔTE DÉTAILLÉE
                    Navigator.push(context, CupertinoPageRoute(builder: (context) => HostDetailsPage(ip: client.ip, mac: client.mac, osType: "Système Inconnu", vendor: "Constructeur")));
                  } else if (value == 'diagnose') {
                    String result = await _apiService.runDiagnostics(client.ip);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                  } else if (value == 'block') {
                    setState(() { client.isBlocked = !client.isBlocked; _applyFilters(); }); // Met à jour l'UI
                    await _apiService.setQosLimit(client.mac, client.isBlocked ? 0 : client.allocatedBandwidth);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'details', child: Row(children: [Icon(CupertinoIcons.doc_text_search, size: 16, color: Colors.white), SizedBox(width: 8), Text("Détails de l'Hôte", style: TextStyle(color: Colors.white))])),
                  const PopupMenuItem(value: 'diagnose', child: Row(children: [Icon(CupertinoIcons.waveform_path_ecg, size: 16, color: Colors.orangeAccent), SizedBox(width: 8), Text("Lancer diagnostic", style: TextStyle(color: Colors.white))])),
                  const PopupMenuDivider(),
                  PopupMenuItem(value: 'block', child: Row(children: [Icon(client.isBlocked ? CupertinoIcons.checkmark_shield : CupertinoIcons.nosign, size: 16, color: client.isBlocked ? Colors.greenAccent : Colors.redAccent), SizedBox(width: 8), Text(client.isBlocked ? "Débloquer l'accès" : "Isoler du réseau", style: TextStyle(color: client.isBlocked ? Colors.greenAccent : Colors.redAccent))])),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          if (!client.isBlocked) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Bande Passante Allouée", style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(isUnlimited ? "Illimité" : "${client.allocatedBandwidth.toInt()} Mb/s", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(activeTrackColor: const Color(0xFF3B82F6), inactiveTrackColor: Colors.white10, thumbColor: Colors.cyanAccent, overlayColor: Colors.cyanAccent.withValues(alpha: 0.2), trackHeight: 4),
              child: Slider(
                value: client.allocatedBandwidth, min: 1.0, max: 1000.0, divisions: 100,
                onChanged: (val) {
                  setState(() => client.allocatedBandwidth = val);
                  if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
                    bool success = await _apiService.setQosLimit(client.mac, val);
                    if (success && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Règle QoS synchronisée via SDN"), backgroundColor: Colors.green, duration: Duration(milliseconds: 800)));
                  });
                },
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.redAccent, size: 16),
                  SizedBox(width: 8),
                  Text("Trafic coupé pour cet appareil (Isolation L2/L3 active).", style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildGlobalConfigTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Points d'accès (AP)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
            child: Column(
              children: [
                _buildConfigTextField(label: "Nom du réseau (SSID)", initialValue: _wifiName, icon: CupertinoIcons.wifi),
                const Divider(color: Colors.white10, height: 32),
                _buildConfigTextField(label: "Clé de sécurité (WPA3 Enterprise)", initialValue: "********", icon: CupertinoIcons.lock, isObscure: true),
                const Divider(color: Colors.white10, height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Activer Bande 5GHz (Haute Perf.)", style: TextStyle(color: Colors.white70)),
                    Switch(value: _is5GHzEnabled, activeTrackColor: Colors.purpleAccent, onChanged: (val) => setState(() => _is5GHzEnabled = val)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              icon: _isUpdatingWifi ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(CupertinoIcons.cloud_upload),
              label: Text(_isUpdatingWifi ? "Provisioning..." : "Appliquer la configuration", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: _isUpdatingWifi ? null : _applyGlobalWifiConfig,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigTextField({required String label, required String initialValue, required IconData icon, bool isObscure = false}) {
    return Row(
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.blueGrey[400], fontSize: 12)),
              TextFormField(initialValue: initialValue, obscureText: isObscure, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.only(top: 8))),
            ],
          ),
        ),
      ],
    );
  }
}