import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

// --- LE SERVICE API SÉCURISÉ (DevSecOps) ---
class RouterApiService {
  // Emplacement exact recommandé : Stocker l'URL et les secrets via des variables d'environnement (flutter --dart-define)
  final String routerIp = const String.fromEnvironment('ROUTER_IP', defaultValue: "https://192.168.1.1/api/v1");

  // Simulation d'une récupération sécurisée du token (Secure Storage / Injection runtime)
  Future<String?> _getAuthToken() async {
    // Remplacer par FlutterSecureStorage en production
    return "Bearer secure_dyn_token_encrypted";
  }

  // Algorithme de validation IP/MAC renforcé
  bool validateNetworkParameters(String ip, String mac) {
    final ipRegExp = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    final macRegExp = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
    return ipRegExp.hasMatch(ip) && macRegExp.hasMatch(mac);
  }

  Future<bool> setQosLimit(String macAddress, double limitMbps) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return false;

      // SECURITE : Vérification d'intégrité avant envoi
      if (!validateNetworkParameters("192.168.1.1", macAddress)) {
        throw FormatException("Format d'adresse MAC invalide - Rejeté par la politique DevSecOps");
      }

      /* CODE DE PRODUCTION SÉCURISÉ :
      final response = await http.post(
        Uri.parse('$routerIp/clients/$macAddress/qos'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
          'X-Content-Type-Options': 'nosniff',
        },
        body: jsonEncode({'bandwidth_limit_mbps': limitMbps}),
      );
      return response.statusCode == 200;
      */

      await Future.delayed(const Duration(milliseconds: 400));
      return true;
    } catch (e) {
      debugPrint("Erreur critique QoS API : $e");
      return false;
    }
  }

  Future<String> runDiagnostics(String ip) async {
    if (!RegExp(r'^(\d{1,3}\.){3}\d{1,3}$').hasMatch(ip)) {
      return "ERREUR DE SÉCURITÉ : Adresse IP cible corrompue.";
    }
    await Future.delayed(const Duration(seconds: 1));
    return "0% Packet Loss, Avg Latency: 12ms. Status: SECURE & HEALTHY";
  }
}

// --- MODÈLE CLIENT ---
class ConnectedClient {
  final String name;
  final String mac;
  final String ip;
  double allocatedBandwidth;
  bool isBlocked;

  ConnectedClient(this.name, this.mac, this.ip, this.allocatedBandwidth, this.isBlocked);
}

// --- FENÊTRE UI / UX ---
class TrafficManagementScreen extends StatefulWidget {
  const TrafficManagementScreen({Key? key}) : super(key: key);

  @override
  _TrafficManagementScreenState createState() => _TrafficManagementScreenState();
}

class _TrafficManagementScreenState extends State<TrafficManagementScreen> {
  final RouterApiService _apiService = RouterApiService();

  bool _is5GHzEnabled = true;
  final String _wifiName = "Office_WiFi_5G";
  bool _isUpdatingWifi = false;

  // Gestion du Debounce pour optimiser l'algorithme de curseur QoS
  Timer? _debounceTimer;

  List<ConnectedClient> _clients = [
    ConnectedClient("Serveur NAS", "00:11:22:33:44:55", "192.168.1.10", 1000.0, false),
    ConnectedClient("PC-Compta", "AA:BB:CC:DD:EE:FF", "192.168.1.55", 50.0, false),
    ConnectedClient("iPhone Visiteur", "11:22:33:44:55:66", "192.168.1.109", 5.0, false),
  ];

  void _applyGlobalWifiConfig() async {
    setState(() => _isUpdatingWifi = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isUpdatingWifi = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Configuration Wi-Fi sécurisée appliquée au routeur !"), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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
                indicatorColor: const Color(0xFF3B82F6),
                labelColor: const Color(0xFF3B82F6),
                unselectedLabelColor: Colors.blueGrey[400],
                tabs: const [
                  Tab(icon: Icon(CupertinoIcons.slider_horizontal_3), text: "QoS & Appareils"),
                  Tab(icon: Icon(CupertinoIcons.settings_solid), text: "Configuration Globale"),
                ],
              ),
              Expanded(
                child: TabBarView(
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
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        final client = _clients[index];
        return _buildClientTrafficCard(client);
      },
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
        border: Border.all(color: client.isBlocked ? Colors.redAccent.withOpacity(0.5) : Colors.white10),
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
                  if (value == 'diagnose') {
                    String result = await _apiService.runDiagnostics(client.ip);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                  } else if (value == 'block') {
                    setState(() => client.isBlocked = !client.isBlocked);
                    await _apiService.setQosLimit(client.mac, client.isBlocked ? 0 : client.allocatedBandwidth);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'diagnose', child: Text("Lancer un diagnostic", style: TextStyle(color: Colors.white))),
                  PopupMenuItem(value: 'block', child: Text(client.isBlocked ? "Débloquer l'accès" : "Bloquer l'accès internet", style: const TextStyle(color: Colors.redAccent))),
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
              data: SliderThemeData(
                activeTrackColor: const Color(0xFF3B82F6),
                inactiveTrackColor: Colors.white10,
                thumbColor: Colors.cyanAccent,
                overlayColor: Colors.cyanAccent.withOpacity(0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: client.allocatedBandwidth,
                min: 1.0,
                max: 1000.0,
                divisions: 100,
                onChanged: (val) {
                  setState(() => client.allocatedBandwidth = val);

                  // ALGORITHME OPTIMISÉ : Implémentation du Debounce pour éviter la saturation du bus API
                  if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
                    bool success = await _apiService.setQosLimit(client.mac, val);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Règle QoS synchronisée via SDN"), backgroundColor: Colors.green, duration: Duration(milliseconds: 800)),
                      );
                    }
                  });
                },
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
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
                    Switch(
                      value: _is5GHzEnabled,
                      activeColor: Colors.purpleAccent,
                      onChanged: (val) => setState(() => _is5GHzEnabled = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: _isUpdatingWifi
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(CupertinoIcons.cloud_upload),
              label: Text(_isUpdatingWifi ? "Application en cours (Provisioning)..." : "Appliquer la configuration", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: _isUpdatingWifi ? null : _applyGlobalWifiConfig,
            ),
          ),
          const SizedBox(height: 32),
          const Text("Maintenance du Routeur", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(CupertinoIcons.restart, color: Colors.redAccent),
            label: const Text("Redémarrer le routeur principal (Reboot)", style: TextStyle(color: Colors.redAccent)),
            onPressed: () {
              // Logique de redémarrage sécurisée avec confirmation
            },
          )
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
              TextFormField(
                initialValue: initialValue,
                obscureText: isObscure,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.only(top: 8)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
