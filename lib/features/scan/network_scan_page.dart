import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';

const Color kBackgroundColor = Color(0xFF070B14);
const Color kCardColor = Color(0xFF131C2D);
const Color kAccentColor = Color(0xFF00E5FF);
const Color kTextMain = Colors.white;
const Color kTextSecondary = Color(0xFF94A3B8);

// ============================================================
// MODÈLES
// ============================================================

class TcpPortResult {
  final int port;
  final bool connected;
  final int? connectionMs;
  final String status;

  const TcpPortResult({
    required this.port,
    required this.connected,
    required this.status,
    this.connectionMs,
  });
}

class NetworkDevice {
  final String ip;
  final List<TcpPortResult> checks;
  final DateTime checkedAt;

  const NetworkDevice({
    required this.ip,
    required this.checks,
    required this.checkedAt,
  });

  List<int> get openPorts => checks
      .where((result) => result.connected)
      .map((result) => result.port)
      .toList();

  int? get connectionMs {
    for (final result in checks) {
      if (result.connected) return result.connectionMs;
    }
    return null;
  }
}

// ============================================================
// SERVICE TCP
// ============================================================

class NetworkDiscoveryService {
  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
  }

  Future<TcpPortResult> _checkPort(
      String ip,
      int port,
      Duration timeout,
      ) async {
    Socket? socket;
    final watch = Stopwatch()..start();

    try {
      socket = await Socket.connect(ip, port, timeout: timeout);
      watch.stop();

      return TcpPortResult(
        port: port,
        connected: true,
        connectionMs: watch.elapsedMilliseconds,
        status: 'Connexion établie',
      );
    } on TimeoutException {
      return TcpPortResult(
        port: port,
        connected: false,
        status: 'Délai dépassé',
      );
    } on SocketException catch (e) {
      return TcpPortResult(
        port: port,
        connected: false,
        status: 'Connexion non établie : ${e.message}',
      );
    } catch (e) {
      return TcpPortResult(
        port: port,
        connected: false,
        status: 'Erreur : $e',
      );
    } finally {
      watch.stop();
      socket?.destroy();
    }
  }

  Future<void> scan({
    required List<String> targets,
    required List<int> ports,
    required Duration timeout,
    required void Function(int completed, int total) onProgress,
    required void Function(NetworkDevice device) onChecked,
    int concurrency = 8,
  }) async {
    _cancelled = false;

    int nextIndex = 0;
    int completed = 0;

    Future<void> worker() async {
      while (!_cancelled && nextIndex < targets.length) {
        final ip = targets[nextIndex++];
        final checks = <TcpPortResult>[];

        for (final port in ports) {
          if (_cancelled) break;
          checks.add(await _checkPort(ip, port, timeout));
        }

        // Ne pas présenter un hôte partiellement vérifié comme terminé.
        if (_cancelled) return;

        onChecked(
          NetworkDevice(
            ip: ip,
            checks: checks,
            checkedAt: DateTime.now(),
          ),
        );

        completed++;
        onProgress(completed, targets.length);
      }
    }

    final workerCount =
    targets.length < concurrency ? targets.length : concurrency;

    await Future.wait(
      List.generate(workerCount, (_) => worker()),
    );
  }
}

// ============================================================
// PAGE
// ============================================================

class NetworkScanPage extends StatefulWidget {
  const NetworkScanPage({super.key});

  @override
  State<NetworkScanPage> createState() => _NetworkScanPageState();
}

class _NetworkScanPageState extends State<NetworkScanPage> {
  final _targetController =
  TextEditingController(text: '10.237.245.171');

  final _portsController =
  TextEditingController(text: '22,80,443,8080');

  final _toolTargetController =
  TextEditingController(text: '10.237.245.171');

  final _routeTargetController =
  TextEditingController(text: '10.237.245.171');

  final _scanner = NetworkDiscoveryService();

  final List<NetworkDevice> _checkedDevices = [];

  bool _isScanning = false;
  bool _stopRequested = false;
  bool _showAll = false;
  bool _authorized = false;
  bool _toolRunning = false;

  int _completed = 0;
  int _total = 0;
  int _timeoutMs = 1200;

  String _status = 'Prêt. Commence par une seule adresse autorisée.';
  String _console = 'Aucun outil lancé.';
  String _routeOutput = 'Aucun traceroute exécuté.';

  Process? _process;
  Timer? _processTimer;

  bool get _desktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  List<NetworkDevice> get _visibleDevices {
    final devices = _checkedDevices
        .where((device) => _showAll || device.openPorts.isNotEmpty)
        .toList();

    devices.sort((a, b) {
      final aa = a.ip.split('.').map(int.parse).toList();
      final bb = b.ip.split('.').map(int.parse).toList();

      for (int i = 0; i < 4; i++) {
        final comparison = aa[i].compareTo(bb[i]);
        if (comparison != 0) return comparison;
      }
      return 0;
    });

    return devices;
  }

  int get _reachableCount => _checkedDevices
      .where((device) => device.openPorts.isNotEmpty)
      .length;

  @override
  void dispose() {
    _scanner.cancel();
    _processTimer?.cancel();
    _process?.kill();

    _targetController.dispose();
    _portsController.dispose();
    _toolTargetController.dispose();
    _routeTargetController.dispose();

    super.dispose();
  }

  void _notify(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  bool _isIpv4(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;

    return parts.every((part) {
      if (!RegExp(r'^\d{1,3}$').hasMatch(part)) return false;
      final number = int.tryParse(part);
      return number != null && number >= 0 && number <= 255;
    });
  }

  List<String> _parseTargets(String raw) {
    final input = raw.trim();

    if (input.endsWith('/24')) {
      final address = input.substring(0, input.length - 3).trim();

      if (!_isIpv4(address)) {
        throw const FormatException('Adresse IPv4 invalide.');
      }

      final prefix = address.split('.').take(3).join('.');
      return List.generate(254, (index) => '$prefix.${index + 1}');
    }

    if (!_isIpv4(input)) {
      throw const FormatException(
        'Utilise une IPv4 seule ou une IPv4 suivie de /24.',
      );
    }

    return [input];
  }

  List<int> _parsePorts() {
    final values = _portsController.text.split(',');
    final ports = <int>{};

    for (final value in values) {
      final port = int.tryParse(value.trim());

      if (port == null || port < 1 || port > 65535) {
        throw const FormatException(
          'Ports invalides. Exemple : 22,80,443,8080',
        );
      }

      ports.add(port);
    }

    if (ports.length > 16) {
      throw const FormatException(
        'Limite cette vérification à 16 ports maximum.',
      );
    }

    return ports.toList();
  }

  Future<void> _useLocalSubnet() async {
    try {
      final ip = await NetworkInfo().getWifiIP();

      if (!mounted) return;

      if (ip == null || !_isIpv4(ip)) {
        _notify('IPv4 Wi-Fi non disponible. Saisis la cible manuellement.');
        return;
      }

      final prefix = ip.split('.').take(3).join('.');

      setState(() {
        _targetController.text = '$prefix.0/24';
      });

      _notify(
        '/24 proposé à partir de l’IP Wi-Fi : '
            'ce n’est pas une lecture du masque réel.',
      );
    } catch (e) {
      _notify('Lecture Wi-Fi impossible : $e');
    }
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    if (!_authorized) {
      _notify('Confirme d’abord que les cibles sont autorisées.');
      return;
    }

    late final List<String> targets;
    late final List<int> ports;

    try {
      targets = _parseTargets(_targetController.text);
      ports = _parsePorts();
    } on FormatException catch (e) {
      _notify(e.message.toString());
      return;
    }

    if (targets.length > 1) {
      final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmer le périmètre'),
          content: Text(
            'Vérifier ${targets.length} adresses sur '
                '${ports.length} ports ?\n\n'
                'Continue uniquement si tout ce sous-réseau '
                'fait partie de ton périmètre autorisé.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuer'),
            ),
          ],
        ),
      );

      if (approved != true || !mounted) return;
    }

    setState(() {
      _isScanning = true;
      _stopRequested = false;
      _completed = 0;
      _total = targets.length;
      _checkedDevices.clear();
      _status = 'Vérification TCP en cours...';
    });

    try {
      await _scanner.scan(
        targets: targets,
        ports: ports,
        timeout: Duration(milliseconds: _timeoutMs),
        onChecked: (device) {
          if (!mounted) return;
          setState(() => _checkedDevices.add(device));
        },
        onProgress: (completed, total) {
          if (!mounted) return;
          setState(() {
            _completed = completed;
            _total = total;
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _status = _stopRequested
            ? 'Arrêt demandé : $_completed/$_total adresses terminées. '
            '$_reachableCount hôte(s) avec connexion TCP réussie.'
            : 'Vérification terminée : $_completed adresses, '
            '$_reachableCount hôte(s) avec connexion TCP réussie. '
            'Consulte Endpoints.';
      });
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Erreur de vérification : $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  void _stopScan() {
    _scanner.cancel();
    setState(() {
      _stopRequested = true;
      _status =
      'Arrêt demandé. Attente de la fin des connexions en cours...';
    });
  }

  String _csvCell(Object? value) {
    final text = value?.toString() ?? '';
    return '"${text.replaceAll('"', '""')}"';
  }

  String _buildCsv() {
    final rows = <String>[
      'ip,port,connexion_etablie,duree_tcp_ms,statut,date',
    ];

    for (final device in _checkedDevices) {
      for (final check in device.checks) {
        rows.add([
          device.ip,
          check.port,
          check.connected,
          check.connectionMs,
          check.status,
          device.checkedAt.toIso8601String(),
        ].map(_csvCell).join(','));
      }
    }

    return '${rows.join('\r\n')}\r\n';
  }

  Future<void> _exportCsv() async {
    if (_checkedDevices.isEmpty) {
      _notify('Aucun résultat à exporter.');
      return;
    }

    final initialPath = [
      Directory.systemTemp.path,
      'dark_puls_${DateTime.now().millisecondsSinceEpoch}.csv',
    ].join(Platform.pathSeparator);

    final controller = TextEditingController(text: initialPath);

    final path = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enregistrer le CSV'),
        content: SizedBox(
          width: 600,
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Chemin complet du fichier',
              helperText: 'Dossier existant et accessible en écriture.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (path == null || path.isEmpty || !mounted) return;

    try {
      final file = File(path);

      if (await file.exists()) {
        if (!mounted) return;

        final overwrite = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Fichier existant'),
            content: const Text('Remplacer ce fichier ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remplacer'),
              ),
            ],
          ),
        );

        if (overwrite != true) return;
      }

      await file.writeAsString(
        '\uFEFF${_buildCsv()}',
        flush: true,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('CSV enregistré'),
          content: SelectableText(file.absolute.path),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: file.absolute.path),
                );
              },
              child: const Text('Copier le chemin'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } catch (e) {
      _notify('Échec de l’export : $e');
    }
  }

  void _showDetails(NetworkDevice device) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(device.ip),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Vérifié le : ${device.checkedAt.toLocal()}'),
                const SizedBox(height: 12),
                const Text(
                  'OS, constructeur, MAC et TTL : non mesurés '
                      'par cette vérification TCP.',
                ),
                const Divider(),
                for (final check in device.checks)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: SelectableText(
                      'TCP ${check.port} — ${check.status}'
                          '${check.connectionMs == null ? "" : " "
                          "(${check.connectionMs} ms)"}',
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  bool _validToolTarget(String target) {
    return target.isNotEmpty &&
        target.length <= 253 &&
        !target.startsWith('-') &&
        RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(target);
  }

  void _appendOutput(bool route, String value) {
    if (!mounted) return;

    setState(() {
      final previous = route ? _routeOutput : _console;
      var updated = '$previous$value';

      // Limite la mémoire utilisée par la console.
      if (updated.length > 60000) {
        updated = updated.substring(updated.length - 60000);
      }

      if (route) {
        _routeOutput = updated;
      } else {
        _console = updated;
      }
    });
  }

  Future<void> _runTool(String tool, {bool route = false}) async {
    if (_toolRunning) return;

    if (!_desktop) {
      _notify('Les outils natifs de cette page nécessitent un desktop.');
      return;
    }

    if (!_authorized) {
      _notify('Confirme que la cible est autorisée dans Découverte.');
      return;
    }

    final target = (route
        ? _routeTargetController.text
        : _toolTargetController.text)
        .trim();

    if (!_validToolTarget(target)) {
      _notify('Saisis une IPv4 ou un nom DNS, sans URL ni options.');
      return;
    }

    late final String executable;
    late final List<String> arguments;

    switch (tool) {
      case 'Ping':
        executable = 'ping';
        arguments = Platform.isWindows
            ? ['-n', '4', target]
            : ['-c', '4', target];
        break;

      case 'DNS':
        executable = 'nslookup';
        arguments = [target];
        break;

      case 'Traceroute':
        executable = Platform.isWindows ? 'tracert' : 'traceroute';
        arguments = Platform.isWindows
            ? ['-d', '-h', '12', '-w', '1000', target]
            : ['-n', '-m', '12', '-w', '1', target];
        break;

      case 'iperf3':
        executable = 'iperf3';
        arguments = ['-c', target, '-t', '5'];
        break;

      default:
        return;
    }

    setState(() {
      _toolRunning = true;
      final header = '\$ $executable ${arguments.join(" ")}\n\n';

      if (route) {
        _routeOutput = header;
      } else {
        _console = header;
      }
    });

    Process? process;

    try {
      process = await Process.start(
        executable,
        arguments,
        runInShell: false,
      );

      if (!mounted) {
        process.kill();
        return;
      }

      _process = process;

      _processTimer = Timer(const Duration(seconds: 60), () {
        _appendOutput(route, '\nLimite de 60 secondes atteinte.\n');
        process?.kill();
      });

      final outputDone = process.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .forEach((chunk) => _appendOutput(route, chunk));

      final errorDone = process.stderr
          .transform(const Utf8Decoder(allowMalformed: true))
          .forEach((chunk) => _appendOutput(route, chunk));

      final exitCode = await process.exitCode;
      await Future.wait([outputDone, errorDone]);

      _appendOutput(route, '\nFin du processus : code $exitCode.\n');
    } catch (e) {
      process?.kill();
      _appendOutput(
        route,
        '\nÉchec : $e\n'
            'Vérifie la présence de l’outil et son accès depuis le PATH.\n',
      );
    } finally {
      _processTimer?.cancel();
      _processTimer = null;
      _process = null;

      if (mounted) {
        setState(() => _toolRunning = false);
      }
    }
  }

  void _stopTool() {
    final sent = _process?.kill() ?? false;
    _notify(
      sent
          ? 'Demande d’arrêt envoyée au processus.'
          : 'Aucun processus actif à arrêter pour le moment.',
    );
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: kCardColor,
      border: const OutlineInputBorder(),
    );
  }

  Widget _outputBox(String output) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectableText(
        output,
        style: const TextStyle(
          color: Colors.greenAccent,
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _scannerTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'DÉCOUVERTE TCP — CIBLES AUTORISÉES',
          style: TextStyle(color: kAccentColor),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _targetController,
          enabled: !_isScanning,
          decoration: _decoration(
            'IPv4 ou sous-réseau /24',
            hint: '10.237.245.171',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _portsController,
          enabled: !_isScanning,
          decoration: _decoration('Ports TCP séparés par des virgules'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _timeoutMs,
          decoration: _decoration('Délai maximal par connexion'),
          items: const [
            DropdownMenuItem(value: 1200, child: Text('1,2 seconde')),
            DropdownMenuItem(value: 2500, child: Text('2,5 secondes')),
            DropdownMenuItem(value: 5000, child: Text('5 secondes')),
          ],
          onChanged: _isScanning
              ? null
              : (value) {
            if (value != null) {
              setState(() => _timeoutMs = value);
            }
          },
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Je suis autorisé à vérifier les cibles sélectionnées.',
          ),
          value: _authorized,
          onChanged: _isScanning
              ? null
              : (value) => setState(() => _authorized = value ?? false),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: _isScanning ? null : _startScan,
              icon: const Icon(Icons.search),
              label: const Text('Vérifier'),
            ),
            OutlinedButton.icon(
              onPressed: _isScanning ? _stopScan : null,
              icon: const Icon(Icons.stop),
              label: const Text('Arrêter'),
            ),
            TextButton(
              onPressed: _isScanning ? null : _useLocalSubnet,
              child: const Text('Proposer le /24 du Wi-Fi'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_isScanning)
          LinearProgressIndicator(
            value: _total == 0 ? null : _completed / _total,
          ),
        const SizedBox(height: 12),
        Text(_status),
        const SizedBox(height: 8),
        Text('Adresses terminées : $_completed / $_total'),
        const SizedBox(height: 20),
        const Text(
          'Une connexion TCP réussie confirme un service accessible. '
              'Aucune connexion réussie ne prouve pas que l’hôte est absent. '
              'Le temps affiché est une durée TCP, pas un ping ICMP.',
          style: TextStyle(color: kTextSecondary),
        ),
      ],
    );
  }

  Widget _endpointsTab() {
    final devices = _visibleDevices;

    return Column(
      children: [
        SwitchListTile(
          title: const Text('Afficher aussi les cibles sans connexion réussie'),
          value: _showAll,
          onChanged: (value) => setState(() => _showAll = value),
        ),
        Wrap(
          spacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed:
              _isScanning || _checkedDevices.isEmpty ? null : _exportCsv,
              icon: const Icon(Icons.save_alt),
              label: const Text('Exporter CSV'),
            ),
            TextButton(
              onPressed: _checkedDevices.isEmpty
                  ? null
                  : () async {
                await Clipboard.setData(
                  ClipboardData(text: _buildCsv()),
                );
                _notify('Résultats CSV copiés.');
              },
              child: const Text('Copier CSV'),
            ),
          ],
        ),
        Expanded(
          child: devices.isEmpty
              ? const Center(
            child: Text('Aucun résultat correspondant au filtre.'),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              final reachable = device.openPorts.isNotEmpty;

              return Card(
                color: kCardColor,
                child: ListTile(
                  leading: Icon(
                    reachable ? Icons.computer : Icons.help_outline,
                    color: reachable
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                  ),
                  title: Text(device.ip),
                  subtitle: Text(
                    reachable
                        ? 'Ports : ${device.openPorts.join(", ")}\n'
                        'Première connexion TCP : '
                        '${device.connectionMs} ms'
                        : 'Aucune connexion TCP établie '
                        'sur les ports testés.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDetails(device),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _routeTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'NETPATH — SORTIE RÉELLE DU TRACEROUTE',
          style: TextStyle(color: kAccentColor),
        ),
        const SizedBox(height: 12),
        const Text(
          'Aucune route simulée. Les sauts sont affichés '
              'dans la sortie de l’outil système.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _routeTargetController,
          enabled: !_toolRunning,
          decoration: _decoration('Cible autorisée'),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            FilledButton(
              onPressed: _toolRunning
                  ? null
                  : () => _runTool('Traceroute', route: true),
              child: const Text('Tracer la route'),
            ),
            OutlinedButton(
              onPressed: _toolRunning ? _stopTool : null,
              child: const Text('Arrêter l’outil'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _outputBox(_routeOutput),
      ],
    );
  }

  Widget _toolkitTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: _toolTargetController,
          enabled: !_toolRunning,
          decoration: _decoration('IPv4 ou nom DNS autorisé'),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final name in ['Ping', 'DNS', 'iperf3'])
              FilledButton(
                onPressed: _toolRunning ? null : () => _runTool(name),
                child: Text(name),
              ),
            OutlinedButton(
              onPressed: _toolRunning ? _stopTool : null,
              child: const Text('Arrêter l’outil'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'iperf3 mesure le débit vers un serveur iperf3 de laboratoire, '
              'pas automatiquement le débit Internet. '
              'L’outil doit être installé sur le client et un serveur '
              'doit être démarré sur la cible.',
          style: TextStyle(color: kTextSecondary),
        ),
        const SizedBox(height: 16),
        if (_toolRunning) const LinearProgressIndicator(),
        const SizedBox(height: 12),
        _outputBox(_console),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = ThemeData.dark();

    return Theme(
      data: darkTheme.copyWith(
        scaffoldBackgroundColor: kBackgroundColor,
        colorScheme: darkTheme.colorScheme.copyWith(
          primary: kAccentColor,
          secondary: kAccentColor,
          surface: kCardColor,
        ),
      ),
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: kCardColor,
            title: const Text('Dark Puls — Scanner et diagnostic'),
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(icon: Icon(Icons.search), text: 'Découverte'),
                Tab(icon: Icon(Icons.computer), text: 'Endpoints'),
                Tab(icon: Icon(Icons.route), text: 'NetPath'),
                Tab(icon: Icon(Icons.build), text: 'Boîte à outils'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _scannerTab(),
              _endpointsTab(),
              _routeTab(),
              _toolkitTab(),
            ],
          ),
        ),
      ),
    );
  }
}