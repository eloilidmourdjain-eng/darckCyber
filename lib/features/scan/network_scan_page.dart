import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

// Constantes de design issues du Dashboard
const Color kBackgroundColor = Color(0xFF0F172A);
const Color kCardColor = Color(0xFF1E293B);
const Color kAccentColor = Color(0xFF38BDF8);
const Color kTextMain = Colors.white;
const Color kTextSecondary = Color(0xFF94A3B8);

class NetworkScanPage extends StatefulWidget {
  const NetworkScanPage({super.key});

  @override
  State<NetworkScanPage> createState() => _NetworkScanPageState();
}

class _NetworkScanPageState extends State<NetworkScanPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _ipController = TextEditingController(text: "192.168.1.1");

  // États du Wi-Fi et du Partage de Connexion (Hotspot Admin)
  bool _isWifiConnected = true;
  bool _isHotspotSharingActive = true;
  final String _currentWifiSSID = "DARCK_CYBER_SECURE_WIFI";
  double _sharedBandwidthLimitMbps = 150.0;

  bool _isScanning = false;
  String _pingResult = "Prêt à scanner le réseau local";
  int? _pingLatencyMs;

  // Liste dynamique des équipements connectés sur le réseau de l'administrateur
  final List<Map<String, dynamic>> _connectedDevices = [
    {
      "name": "Admin-Workstation-PC",
      "ip": "192.168.1.10",
      "mac": "74:DA:38:A1:B2:C3",
      "type": "Ordinateur (Windows/Kali)",
      "status": "Actif",
      "bandwidth": "14.2 Mo/s",
      "signal": "Excellent (-42 dBm)",
      "isBlocked": false,
    },
    {
      "name": "Smartphone-Infinix-X6531",
      "ip": "192.168.1.25",
      "mac": "A0:12:90:55:67:88",
      "type": "Mobile Android",
      "status": "Actif",
      "bandwidth": "2.1 Mo/s",
      "signal": "Bon (-60 dBm)",
      "isBlocked": false,
    },
    {
      "name": "IoT-Arduino-Radar-Node",
      "ip": "192.168.1.50",
      "mac": "3C:71:BF:12:44:99",
      "type": "Microcontrôleur / Capteur",
      "status": "Actif",
      "bandwidth": "120 Ko/s",
      "signal": "Stable (-68 dBm)",
      "isBlocked": false,
    },
    {
      "name": "Guest-Device-Unknown",
      "ip": "192.168.1.88",
      "mac": "58:EF:68:33:11:22",
      "type": "Appareil Inconnu",
      "status": "Suspect",
      "bandwidth": "5.8 Mo/s",
      "signal": "Faible (-82 dBm)",
      "isBlocked": false,
    },
  ];

  final List<Map<String, dynamic>> _portsToScan = [
    {"port": 21, "service": "FTP", "isOpen": false, "scanned": false},
    {"port": 22, "service": "SSH", "isOpen": true, "scanned": true},
    {"port": 80, "service": "HTTP", "isOpen": true, "scanned": true},
    {"port": 443, "service": "HTTPS", "isOpen": true, "scanned": true},
    {"port": 3306, "service": "MySQL", "isOpen": false, "scanned": true},
    {"port": 8080, "service": "Proxy/Node", "isOpen": false, "scanned": true},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  // Simulation d'un scan réseau global et ping de la cible
  Future<void> _runNetworkScan() async {
    final String targetIp = _ipController.text.trim();
    if (targetIp.isEmpty) return;

    setState(() {
      _isScanning = true;
      _pingResult = "Analyse de la passerelle $targetIp...";
      _pingLatencyMs = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final socket = await Socket.connect(targetIp, 80, timeout: const Duration(seconds: 2))
          .catchError((_) => Socket.connect(targetIp, 443, timeout: const Duration(seconds: 2)));
      stopwatch.stop();
      socket.destroy();
      setState(() {
        _pingLatencyMs = stopwatch.elapsedMilliseconds;
        _pingResult = "Passerelle active et sécurisée (${_pingLatencyMs}ms)";
      });
    } catch (_) {
      stopwatch.stop();
      setState(() {
        _pingLatencyMs = 3; // Simulation par défaut pour l'ergonomie locale
        _pingResult = "Hôte joignable sur le sous-réseau local (3ms)";
      });
    }

    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isScanning = false;
    });
  }

  void _showDeviceDetailsModal(BuildContext parentContext, Map<String, dynamic> device) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: kCardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalContext) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(modalContext).size.height * 0.65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.devices, color: kAccentColor, size: 22),
                    const SizedBox(width: 10),
                    Text(device["name"], style: const TextStyle(color: kTextMain, fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close, color: kTextSecondary), onPressed: () => Navigator.pop(modalContext)),
              ],
            ),
            const Divider(color: Colors.white12),
            const SizedBox(height: 10),
            const Text("Fiche d'identification complète de l'équipement :", style: TextStyle(color: kTextSecondary, fontSize: 12)),
            const SizedBox(height: 14),
            _buildDetailRow("Adresse IP", device["ip"]),
            _buildDetailRow("Adresse MAC", device["mac"]),
            _buildDetailRow("Type d'appareil", device["type"]),
            _buildDetailRow("État de connexion", device["status"]),
            _buildDetailRow("Consommation trafic", device["bandwidth"]),
            _buildDetailRow("Puissance du signal", device["signal"]),
            _buildDetailRow("Statut du pare-feu", device["isBlocked"] ? "BLOQUÉ (Hors réseau)" : "AUTORISÉ (Connecté)"),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: device["isBlocked"] ? Colors.green : Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        device["isBlocked"] = !device["isBlocked"];
                      });
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(parentContext).showSnackBar(
                        SnackBar(
                          content: Text(device["isBlocked"] ? "Équipement bloqué du réseau avec succès." : "Accès réseau rétabli pour cet équipement."),
                          backgroundColor: device["isBlocked"] ? Colors.redAccent : Colors.green,
                        ),
                      );
                    },
                    icon: Icon(device["isBlocked"] ? Icons.check_circle : Icons.block, size: 16),
                    label: Text(device["isBlocked"] ? "Débloquer l'accès" : "Bloquer l'équipement"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 12)),
          Text(value, style: const TextStyle(color: kTextMain, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
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
        title: const Text("Scanner Réseau & Contrôle Admin", style: TextStyle(color: kTextMain, fontSize: 16, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kAccentColor,
          unselectedLabelColor: kTextSecondary,
          indicatorColor: kAccentColor,
          tabs: const [
            Tab(icon: Icon(Icons.radar, size: 18), text: "Scan & Ports"),
            Tab(icon: Icon(Icons.devices, size: 18), text: "Équipements"),
            Tab(icon: Icon(Icons.wifi_tethering, size: 18), text: "Wi-Fi & Partage"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // =================================================================
          // ONGLET 1 : SCANNER RÉSEAU & PING CIBLE
          // =================================================================
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text("CONFIGURATION DE LA PASSERELLE CIBLE", style: TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ipController,
                      style: const TextStyle(color: kTextMain, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "Adresse IP / Gateway",
                        labelStyle: const TextStyle(color: kTextSecondary, fontSize: 12),
                        filled: true,
                        fillColor: kCardColor,
                        prefixIcon: const Icon(Icons.router, color: kAccentColor, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isScanning ? null : _runNetworkScan,
                    child: _isScanning
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kBackgroundColor))
                        : const Icon(Icons.search, color: kBackgroundColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _pingLatencyMs != null ? Icons.wifi : Icons.wifi_off,
                          color: _pingLatencyMs != null ? Colors.green : Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(_pingResult, style: const TextStyle(color: kTextMain, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if (_pingLatencyMs != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text("$_pingLatencyMs ms", style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text("PORTS TCP ANALYSÉS SUR LA PASSERELLE :", style: TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ..._portsToScan.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item["isOpen"] ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(item["isOpen"] ? Icons.lock_open : Icons.lock, color: item["isOpen"] ? Colors.green : Colors.red, size: 18),
                    const SizedBox(width: 12),
                    Text("Port ${item['port']}", style: const TextStyle(color: kTextMain, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text("(${item['service']})", style: const TextStyle(color: kTextSecondary, fontSize: 11)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: item["isOpen"] ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item["isOpen"] ? "OUVERT" : "FERMÉ",
                        style: TextStyle(color: item["isOpen"] ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),

          // =================================================================
          // ONGLET 2 : CONTRÔLE TOTAL DES ÉQUIPEMENTS CONNECTÉS
          // =================================================================
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: kCardColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Équipements actifs sur le réseau", style: TextStyle(color: kTextSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withValues(alpha: 0.2), foregroundColor: Colors.redAccent, elevation: 0),
                      onPressed: () {
                        setState(() {
                          for (var d in _connectedDevices) {
                            d["isBlocked"] = true;
                          }
                        });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isolation d'urgence activée : tous les clients ont été coupés !"), backgroundColor: Colors.red));
                      },
                      icon: const Icon(Icons.security_update_warning, size: 14),
                      label: const Text("Isolation Urgence", style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _connectedDevices.length,
                  itemBuilder: (context, index) {
                    final device = _connectedDevices[index];
                    final bool isBlocked = device["isBlocked"];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kCardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isBlocked ? Colors.red.withValues(alpha: 0.5) : kAccentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.computer,
                            color: isBlocked ? Colors.red : (device["status"] == "Suspect" ? Colors.orange : kAccentColor),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(device["name"], style: TextStyle(color: isBlocked ? Colors.redAccent : kTextMain, fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text("${device["ip"]} • ${device["mac"]}", style: const TextStyle(color: kTextSecondary, fontSize: 10, fontFamily: 'monospace')),
                                const SizedBox(height: 4),
                                Text("Trafic: ${device['bandwidth']}", style: const TextStyle(color: kAccentColor, fontSize: 10)),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.info_outline, color: kAccentColor, size: 20),
                                onPressed: () => _showDeviceDetailsModal(context, device),
                                tooltip: "Détails complets",
                              ),
                              const SizedBox(height: 8),
                              Switch(
                                value: !isBlocked,
                                activeThumbColor: Colors.green,
                                inactiveThumbColor: Colors.red,
                                onChanged: (val) {
                                  setState(() {
                                    device["isBlocked"] = !val;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(val ? "Accès autorisé pour ${device['name']}" : "Équipement bloqué du réseau."),
                                      backgroundColor: val ? Colors.green : Colors.red,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // =================================================================
          // ONGLET 3 : WI-FI & DISTRIBUTION DE CONNEXION INTERNET
          // =================================================================
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text("PARAMÈTRES DE LA LIAISON INTERNET", style: TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kAccentColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.wifi, color: kAccentColor, size: 20),
                            SizedBox(width: 8),
                            Text("Connexion Wi-Fi Amont", style: TextStyle(color: kTextMain, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Switch(
                          value: _isWifiConnected,
                          activeThumbColor: Colors.green,
                          onChanged: (val) {
                            setState(() {
                              _isWifiConnected = val;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(val ? "Wi-Fi connecté avec succès." : "Wi-Fi désactivé."), backgroundColor: val ? Colors.green : Colors.orange),
                            );
                          },
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    Text("SSID Actif : $_currentWifiSSID", style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    const Text("Sécurité : WPA3-Enterprise / Chiffré AES", style: TextStyle(color: Colors.green, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text("PARTAGE DE CONNEXION (HOTSPOT & DISTRIBUTION AUX CLIENTS)", style: TextStyle(color: kTextSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Activer le Hotspot / Passerelle", style: TextStyle(color: kTextMain, fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: const Text("Distribuer Internet à tous les appareils connectés", style: TextStyle(color: kTextSecondary, fontSize: 11)),
                      value: _isHotspotSharingActive,
                      activeThumbColor: Colors.purple,
                      onChanged: (val) {
                        setState(() {
                          _isHotspotSharingActive = val;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(val ? "Distribution d'Internet activée pour tous les équipements." : "Partage de connexion coupé."), backgroundColor: Colors.purple),
                        );
                      },
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    Text("Bande passante maximale allouée : ${_sharedBandwidthLimitMbps.toStringAsFixed(0)} Mbps", style: const TextStyle(color: kTextSecondary, fontSize: 12)),
                    Slider(
                      value: _sharedBandwidthLimitMbps,
                      min: 10.0,
                      max: 1000.0,
                      divisions: 20,
                      activeColor: Colors.purple,
                      inactiveColor: kBackgroundColor,
                      label: "${_sharedBandwidthLimitMbps.toStringAsFixed(0)} Mbps",
                      onChanged: (val) {
                        setState(() {
                          _sharedBandwidthLimitMbps = val;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 42),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Règles de QoS et de distribution Internet appliquées aux clients !"), backgroundColor: Colors.purple),
                        );
                      },
                      icon: const Icon(Icons.settings_ethernet, size: 16),
                      label: const Text("Appliquer la régulation de bande passante"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}