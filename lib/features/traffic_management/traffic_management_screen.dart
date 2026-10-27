import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:darck_puls/features/scan/host_details_page.dart';

// ============================================================
// SERVICE DE DÉMONSTRATION
// ============================================================

class DemoRouterApiService {
  /// Aucun appel réseau n'est effectué dans cette version.
  /// Les méthodes simulent une latence et retournent un résultat
  /// explicitement qualifié de démonstration.
  Future<SimulationResult> setQosLimit({
    required String macAddress,
    required double limitMbps,
  }) async {
    if (!_isValidMacAddress(macAddress)) {
      return SimulationResult(
        success: false,
        message: 'Adresse MAC invalide.',
      );
    }

    if (limitMbps < 0 || limitMbps > 1000) {
      return SimulationResult(
        success: false,
        message:
        'Limite invalide : la valeur doit être entre 0 et 1000 Mb/s.',
      );
    }

    await Future.delayed(const Duration(milliseconds: 600));

    return SimulationResult(
      success: true,
      message: limitMbps == 0
          ? 'Action simulée : demande d’isolement enregistrée.'
          : 'Action simulée : limite de '
          '${limitMbps.round()} Mb/s enregistrée.',
    );
  }

  Future<SimulationResult> runDiagnostics(String ip) async {
    if (!_isValidIpv4(ip)) {
      return SimulationResult(
        success: false,
        message: 'Adresse IP invalide.',
      );
    }

    await Future.delayed(const Duration(seconds: 1));

    return SimulationResult(
      success: true,
      message:
      'Diagnostic simulé terminé pour $ip. '
          'Aucune mesure réseau réelle n’a été effectuée.',
    );
  }

  Future<SimulationResult> applyWifiConfiguration({
    required String ssid,
    required String password,
    required bool enable5GHz,
  }) async {
    if (ssid.trim().length < 2 || ssid.trim().length > 32) {
      return SimulationResult(
        success: false,
        message:
        'SSID invalide : utilise entre 2 et 32 caractères.',
      );
    }

    if (password.length < 12) {
      return SimulationResult(
        success: false,
        message:
        'Clé trop courte : utilise au moins 12 caractères.',
      );
    }

    await Future.delayed(const Duration(seconds: 1));

    return SimulationResult(
      success: true,
      message:
      'Configuration Wi-Fi simulée enregistrée. '
          'Aucun point d’accès réel n’a été modifié.',
    );
  }

  static bool _isValidIpv4(String value) {
    final parts = value.trim().split('.');
    if (parts.length != 4) return false;

    return parts.every((part) {
      if (!RegExp(r'^\d{1,3}$').hasMatch(part)) return false;
      final number = int.tryParse(part);
      return number != null && number >= 0 && number <= 255;
    });
  }

  static bool _isValidMacAddress(String value) {
    return RegExp(
      r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$',
    ).hasMatch(value.trim());
  }
}

class SimulationResult {
  final bool success;
  final String message;

  const SimulationResult({
    required this.success,
    required this.message,
  });
}

// ============================================================
// MODÈLE CLIENT
// ============================================================

class ConnectedClient {
  final String name;
  final String mac;
  final String ip;
  double allocatedBandwidth;
  bool isBlocked;

  ConnectedClient({
    required this.name,
    required this.mac,
    required this.ip,
    required this.allocatedBandwidth,
    required this.isBlocked,
  });
}

// ============================================================
// ÉCRAN
// ============================================================

class TrafficManagementScreen extends StatefulWidget {
  const TrafficManagementScreen({super.key});

  @override
  State<TrafficManagementScreen> createState() =>
      _TrafficManagementScreenState();
}

class _TrafficManagementScreenState
    extends State<TrafficManagementScreen> {
  final DemoRouterApiService _apiService =
  DemoRouterApiService();

  bool _is5GHzEnabled = true;
  bool _isUpdatingWifi = false;

  final TextEditingController _ssidController =
  TextEditingController(text: 'Office_WiFi_5G');
  final TextEditingController _passwordController =
  TextEditingController(text: '');
  final TextEditingController _searchController =
  TextEditingController();

  Timer? _debounceTimer;

  String _currentFilter = 'ALL';

  final List<ConnectedClient> _masterClients = [
    ConnectedClient(
      name: 'Serveur NAS',
      mac: '00:11:22:33:44:55',
      ip: '192.168.1.10',
      allocatedBandwidth: 1000,
      isBlocked: false,
    ),
    ConnectedClient(
      name: 'PC-02',
      mac: 'AA:BB:CC:DD:EE:FF',
      ip: '192.168.1.55',
      allocatedBandwidth: 50,
      isBlocked: false,
    ),
    ConnectedClient(
      name: 'Mobile visiteur',
      mac: '11:22:33:44:55:66',
      ip: '192.168.1.109',
      allocatedBandwidth: 5,
      isBlocked: true,
    ),
  ];

  List<ConnectedClient> _filteredClients = [];

  @override
  void initState() {
    super.initState();
    _applyFilters();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _ssidController.dispose();
    _passwordController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredClients = _masterClients.where((client) {
        final matchesSearch = query.isEmpty ||
            client.name.toLowerCase().contains(query) ||
            client.ip.contains(query) ||
            client.mac.toLowerCase().contains(query);

        final matchesStatus = _currentFilter == 'ALL' ||
            (_currentFilter == 'ACTIVE' && !client.isBlocked) ||
            (_currentFilter == 'BLOCKED' && client.isBlocked);

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _notify(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError ? Colors.redAccent : Colors.blueGrey,
      ),
    );
  }

  // ============================================================
  // ACTIONS SIMULÉES
  // ============================================================

  Future<void> _toggleIsolation(ConnectedClient client) async {
    final nextState = !client.isBlocked;

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          nextState
              ? 'Confirmer l’isolement simulé'
              : 'Confirmer le rétablissement simulé',
        ),
        content: Text(
          'Cible : ${client.name} (${client.ip})\n\n'
              'Cette démonstration ne modifie aucun équipement réel.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (approved != true || !mounted) return;

    final result = await _apiService.setQosLimit(
      macAddress: client.mac,
      limitMbps: nextState ? 0 : client.allocatedBandwidth,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        client.isBlocked = nextState;
      });

      _applyFilters();
    }

    _notify(
      result.message,
      isError: !result.success,
    );
  }

  Future<void> _updateBandwidth(
      ConnectedClient client,
      double value,
      ) async {
    final result = await _apiService.setQosLimit(
      macAddress: client.mac,
      limitMbps: value,
    );

    if (!mounted) return;

    _notify(
      result.message,
      isError: !result.success,
    );
  }

  Future<void> _runDiagnostics(ConnectedClient client) async {
    final result = await _apiService.runDiagnostics(client.ip);

    if (!mounted) return;

    _notify(
      result.message,
      isError: !result.success,
    );
  }

  Future<void> _applyWifiConfiguration() async {
    if (_isUpdatingWifi) return;

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la configuration simulée'),
        content: const Text(
          'Cette action enregistre une configuration Wi-Fi '
              'de démonstration. Aucun point d’accès réel '
              'n’est modifié.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simuler'),
          ),
        ],
      ),
    );

    if (approved != true || !mounted) return;

    setState(() {
      _isUpdatingWifi = true;
    });

    final result = await _apiService.applyWifiConfiguration(
      ssid: _ssidController.text,
      password: _passwordController.text,
      enable5GHz: _is5GHzEnabled,
    );

    if (!mounted) return;

    setState(() {
      _isUpdatingWifi = false;
    });

    _notify(
      result.message,
      isError: !result.success,
    );
  }

  // ============================================================
  // INTERFACE
  // ============================================================

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
                padding: EdgeInsets.all(24),
                child: Text(
                  'Gestion du trafic — démonstration',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              TabBar(
                indicatorColor: const Color(0xFF3B82F6),
                labelColor: const Color(0xFF3B82F6),
                unselectedLabelColor: Colors.blueGrey,
                tabs: const [
                  Tab(
                    icon: Icon(
                      CupertinoIcons.slider_horizontal_3,
                    ),
                    text: 'QoS et appareils',
                  ),
                  Tab(
                    icon: Icon(CupertinoIcons.settings_solid),
                    text: 'Wi-Fi simulé',
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildTrafficTab(),
                    _buildWifiTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrafficTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    prefixIcon: const Icon(
                      CupertinoIcons.search,
                      color: Colors.blueGrey,
                      size: 18,
                    ),
                    hintText: 'Nom, IP ou adresse MAC...',
                    hintStyle:
                    const TextStyle(color: Colors.white30),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => _applyFilters(),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: const Color(0xFF1E293B),
                  value: _currentFilter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'ALL',
                      child: Text('Tous'),
                    ),
                    DropdownMenuItem(
                      value: 'ACTIVE',
                      child: Text('Non isolés'),
                    ),
                    DropdownMenuItem(
                      value: 'BLOCKED',
                      child: Text('Isolés (démo)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _currentFilter = value;
                    });

                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredClients.isEmpty
              ? const Center(
            child: Text(
              'Aucun appareil ne correspond aux filtres.',
              style: TextStyle(color: Colors.white38),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
            ),
            itemCount: _filteredClients.length,
            itemBuilder: (context, index) =>
                _buildClientCard(
                  _filteredClients[index],
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientCard(ConnectedClient client) {
    final isUnlimited =
        client.allocatedBandwidth >= 1000;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: client.isBlocked
              ? Colors.redAccent.withValues(alpha: 0.5)
              : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                client.isBlocked
                    ? CupertinoIcons.nosign
                    : CupertinoIcons.device_laptop,
                color: client.isBlocked
                    ? Colors.redAccent
                    : Colors.cyanAccent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${client.ip} • ${client.mac}',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: const Color(0xFF0F172A),
                icon: const Icon(
                  CupertinoIcons.ellipsis_vertical,
                  color: Colors.white70,
                ),
                onSelected: (value) {
                  if (value == 'details') {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => HostDetailsPage(
                          ip: client.ip,
                          mac: client.mac,
                          osType: 'Non identifié',
                          vendor: 'Non identifié',
                        ),
                      ),
                    );
                  } else if (value == 'diagnose') {
                    _runDiagnostics(client);
                  } else if (value == 'block') {
                    _toggleIsolation(client);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Text('Détails'),
                  ),
                  const PopupMenuItem(
                    value: 'diagnose',
                    child: Text('Diagnostic simulé'),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'block',
                    child: Text(
                      client.isBlocked
                          ? 'Rétablissement simulé'
                          : 'Isolement simulé',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!client.isBlocked) ...[
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Limite simulée',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  isUnlimited
                      ? '1000 Mb/s'
                      : '${client.allocatedBandwidth.round()} Mb/s',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: client.allocatedBandwidth,
              min: 1,
              max: 1000,
              divisions: 100,
              onChanged: (value) {
                setState(() {
                  client.allocatedBandwidth = value;
                });

                _debounceTimer?.cancel();
                _debounceTimer = Timer(
                  const Duration(milliseconds: 500),
                      () => _updateBandwidth(client, value),
                );
              },
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Isolement simulé : aucune règle réelle '
                    'n’a été appliquée.',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWifiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuration Wi-Fi simulée',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aucun point d’accès réel n’est contacté.',
            style: TextStyle(color: Colors.white38),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _ssidController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nom du réseau (SSID)',
                    prefixIcon: Icon(CupertinoIcons.wifi),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText:
                    'Clé de démonstration (12 caractères min.)',
                    prefixIcon: Icon(CupertinoIcons.lock),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Activer la bande 5 GHz',
                    style: TextStyle(color: Colors.white70),
                  ),
                  value: _is5GHzEnabled,
                  onChanged: (value) {
                    setState(() {
                      _is5GHzEnabled = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _isUpdatingWifi
                  ? null
                  : _applyWifiConfiguration,
              icon: _isUpdatingWifi
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.cloud_upload),
              label: Text(
                _isUpdatingWifi
                    ? 'Simulation...'
                    : 'Simuler l’application',
              ),
            ),
          ),
        ],
      ),
    );
  }
}