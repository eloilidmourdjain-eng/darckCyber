import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

// ============================================================
// MODÈLES
// ============================================================

class ConfigBackup {
  final String id;
  final DateTime timestamp;
  final String author;
  final String description;
  final bool markedStable;

  const ConfigBackup({
    required this.id,
    required this.timestamp,
    required this.author,
    required this.description,
    required this.markedStable,
  });
}

class SystemLog {
  final String id;
  final DateTime timestamp;
  final String event;
  final bool immutable;
  String? editableNote;

  SystemLog({
    required this.id,
    required this.timestamp,
    required this.event,
    required this.immutable,
    this.editableNote,
  });
}

class MaintenanceTask {
  final String id;
  final String title;
  final DateTime scheduledAt;
  final String status;

  MaintenanceTask({
    required this.id,
    required this.title,
    required this.scheduledAt,
    required this.status,
  });
}

class VastInstance {
  final int id;
  final String? label;
  final String? actualStatus;
  final String? gpuName;
  final double? dphTotal;

  VastInstance({
    required this.id,
    this.label,
    this.actualStatus,
    this.gpuName,
    this.dphTotal,
  });

  factory VastInstance.fromJson(Map<String, dynamic> json) {
    return VastInstance(
      id: json['id'] is int ? json['id'] as int : 0,
      label: json['label']?.toString(),
      actualStatus: json['actual_status']?.toString(),
      gpuName: json['gpu_name']?.toString(),
      dphTotal: json['dph_total'] is num
          ? (json['dph_total'] as num).toDouble()
          : null,
    );
  }
}

class VastOffer {
  final int id;
  final String? gpuName;
  final double? dphTotal;
  final double? reliability;

  VastOffer({
    required this.id,
    this.gpuName,
    this.dphTotal,
    this.reliability,
  });

  factory VastOffer.fromJson(Map<String, dynamic> json) {
    return VastOffer(
      id: json['id'] is int ? json['id'] as int : 0,
      gpuName: json['gpu_name']?.toString(),
      dphTotal: json['dph_total'] is num
          ? (json['dph_total'] as num).toDouble()
          : null,
      reliability: json['reliability2'] is num
          ? (json['reliability2'] as num).toDouble()
          : null,
    );
  }
}

class ApiResult<T> {
  final bool success;
  final T? data;
  final String message;

  const ApiResult({
    required this.success,
    required this.message,
    this.data,
  });
}

// ============================================================
// SERVICE VAST.AI RÉEL
// ============================================================

class VastAiService {
  static const String baseUrl = 'https://console.vast.ai/api/v0';

  final http.Client _client = http.Client();

  Future<ApiResult<List<VastInstance>>> listInstances(
      String apiKey,
      ) async {
    try {
      final response = await _client
          .get(
        Uri.parse('$baseUrl/instances/'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Accept': 'application/json',
        },
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const ApiResult(
          success: false,
          message:
          'Clé API refusée par Vast.ai. Vérifie la clé et ses droits.',
        );
      }

      if (response.statusCode != 200) {
        return ApiResult(
          success: false,
          message:
          'Vast.ai a répondu HTTP ${response.statusCode}.',
        );
      }

      final decoded =
      jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! Map<String, dynamic>) {
        return const ApiResult(
          success: false,
          message: 'Réponse Vast.ai inattendue.',
        );
      }

      final rows = decoded['instances'];

      if (rows is! List) {
        return const ApiResult(
          success: false,
          message:
          'Champ "instances" absent de la réponse Vast.ai.',
        );
      }

      final instances = <VastInstance>[];

      for (final row in rows) {
        if (row is Map<String, dynamic>) {
          instances.add(VastInstance.fromJson(row));
        }
      }

      return ApiResult(
        success: true,
        message: '${instances.length} instance(s) récupérée(s).',
        data: instances,
      );
    } on TimeoutException {
      return const ApiResult(
        success: false,
        message: 'Délai dépassé lors de l’appel à Vast.ai.',
      );
    } catch (e) {
      return ApiResult(
        success: false,
        message: 'Appel Vast.ai impossible : $e',
      );
    }
  }

  Future<ApiResult<List<VastOffer>>> searchOffers({
    required String apiKey,
    required String gpuName,
    required double maxDph,
  }) async {
    try {
      final response = await _client
          .post(
        Uri.parse('$baseUrl/bundles/'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'verified': {'eq': true},
          'rentable': {'eq': true},
          'gpu_name': {'eq': gpuName},
          'num_gpus': {'eq': 1},
          'dph_total': {'lte': maxDph},
          'order': [
            ['dph_total', 'asc']
          ],
          'type': 'on-demand',
          'limit': 5,
        }),
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const ApiResult(
          success: false,
          message:
          'Clé API refusée par Vast.ai. Vérifie la clé et ses droits.',
        );
      }

      if (response.statusCode != 200) {
        return ApiResult(
          success: false,
          message:
          'Recherche Vast.ai : HTTP ${response.statusCode}.',
        );
      }

      final decoded =
      jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! Map<String, dynamic>) {
        return const ApiResult(
          success: false,
          message: 'Réponse Vast.ai inattendue.',
        );
      }

      final rows = decoded['offers'];

      if (rows is! List) {
        return const ApiResult(
          success: false,
          message:
          'Champ "offers" absent de la réponse Vast.ai.',
        );
      }

      final offers = <VastOffer>[];

      for (final row in rows) {
        if (row is Map<String, dynamic>) {
          offers.add(VastOffer.fromJson(row));
        }
      }

      return ApiResult(
        success: true,
        message: '${offers.length} offre(s) trouvée(s).',
        data: offers,
      );
    } on TimeoutException {
      return const ApiResult(
        success: false,
        message: 'Délai dépassé lors de la recherche Vast.ai.',
      );
    } catch (e) {
      return ApiResult(
        success: false,
        message: 'Recherche Vast.ai impossible : $e',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

// ============================================================
// ÉCRAN
// ============================================================

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() =>
      _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final VastAiService _vastService = VastAiService();

  // Télémétrie locale de démonstration.
  double _cpuUsage = 45;
  double _ramUsage = 78;
  double _temperature = 62;

  Timer? _telemetryTimer;

  // Vast.ai
  bool _vastLoading = false;
  String? _vastError;
  List<VastInstance> _vastInstances = [];
  List<VastOffer> _vastOffers = [];

  final TextEditingController _vastKeyController =
  TextEditingController();
  final TextEditingController _gpuNameController =
  TextEditingController(text: 'RTX 4090');
  final TextEditingController _maxPriceController =
  TextEditingController(text: '0.50');

  // Diagnostics
  bool _isRunningCheck = false;
  double _checkProgress = 0;

  // Maintenance
  final TextEditingController _taskTitleController =
  TextEditingController();
  DateTime? _selectedTaskDate;
  TimeOfDay? _selectedTaskTime;

  final List<MaintenanceTask> _tasks = [];
  final List<ConfigBackup> _backups = [];
  final List<SystemLog> _logs = [];

  bool _showImmutableLogs = true;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 5, vsync: this);

    _telemetryTimer = Timer.periodic(
      const Duration(seconds: 3),
          (_) {
        if (!mounted) return;

        setState(() {
          _cpuUsage = 40 + (DateTime.now().millisecond % 20);
          _temperature = 60 + (DateTime.now().millisecond % 5);
        });
      },
    );

    _loadDemonstrationData();
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _tabController.dispose();
    _vastService.dispose();

    _vastKeyController.dispose();
    _gpuNameController.dispose();
    _maxPriceController.dispose();
    _taskTitleController.dispose();

    super.dispose();
  }

  void _loadDemonstrationData() {
    final now = DateTime.now();

    _backups.addAll([
      ConfigBackup(
        id: 'SNAP-2026-10-27-0430',
        timestamp: now.subtract(const Duration(hours: 6)),
        author: 'Automatisation locale',
        description:
        'Instantané de démonstration. Aucun dépôt GitOps réel.',
        markedStable: true,
      ),
      ConfigBackup(
        id: 'SNAP-2026-10-26-1415',
        timestamp: now.subtract(const Duration(days: 1)),
        author: 'Administrateur',
        description:
        'Instantané de démonstration. Restauration non implémentée.',
        markedStable: false,
      ),
    ]);

    _logs.addAll([
      SystemLog(
        id: 'LOG-992',
        timestamp: now.subtract(const Duration(minutes: 5)),
        event:
        'Événement de démonstration : instabilité simulée '
            'd’un port.',
        immutable: true,
      ),
      SystemLog(
        id: 'LOG-991',
        timestamp: now.subtract(const Duration(minutes: 20)),
        event: 'Note d’équipe de démonstration.',
        immutable: false,
        editableNote:
        'Vérifier le câblage lors de la prochaine intervention.',
      ),
    ]);
  }

  void _notify(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        error ? Colors.redAccent : Colors.blueGrey,
      ),
    );
  }

  // ============================================================
  // VAST.AI
  // ============================================================

  String? _validateVastKey() {
    final key = _vastKeyController.text.trim();

    if (key.isEmpty) {
      return 'Saisis ta clé API Vast.ai.';
    }

    if (key.length < 16) {
      return 'Clé API trop courte.';
    }

    return null;
  }

  Future<void> _loadVastInstances() async {
    if (_vastLoading) return;

    final error = _validateVastKey();
    if (error != null) {
      _notify(error, error: true);
      return;
    }

    setState(() {
      _vastLoading = true;
      _vastError = null;
    });

    final result = await _vastService.listInstances(
      _vastKeyController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _vastLoading = false;

      if (result.success) {
        _vastInstances = result.data ?? [];
      } else {
        _vastError = result.message;
      }
    });

    _notify(result.message, error: !result.success);
  }

  Future<void> _searchVastOffers() async {
    if (_vastLoading) return;

    final error = _validateVastKey();
    if (error != null) {
      _notify(error, error: true);
      return;
    }

    final gpuName = _gpuNameController.text.trim();
    final maxPrice =
    double.tryParse(_maxPriceController.text.trim());

    if (gpuName.isEmpty) {
      _notify('Saisis un modèle de GPU.', error: true);
      return;
    }

    if (maxPrice == null || maxPrice <= 0) {
      _notify(
        'Prix maximum invalide. Exemple : 0.50',
        error: true,
      );
      return;
    }

    setState(() {
      _vastLoading = true;
      _vastError = null;
      _vastOffers = [];
    });

    final result = await _vastService.searchOffers(
      apiKey: _vastKeyController.text.trim(),
      gpuName: gpuName,
      maxDph: maxPrice,
    );

    if (!mounted) return;

    setState(() {
      _vastLoading = false;

      if (result.success) {
        _vastOffers = result.data ?? [];
      } else {
        _vastError = result.message;
      }
    });

    _notify(result.message, error: !result.success);
  }

  // ============================================================
  // DIAGNOSTIC LOCAL
  // ============================================================

  Future<void> _runLocalCheck() async {
    if (_isRunningCheck) return;

    setState(() {
      _isRunningCheck = true;
      _checkProgress = 0;
    });

    for (int i = 1; i <= 20; i++) {
      await Future.delayed(
        const Duration(milliseconds: 80),
      );

      if (!mounted) return;

      setState(() {
        _checkProgress = i / 20;
      });
    }

    if (!mounted) return;

    setState(() {
      _isRunningCheck = false;
    });

    _notify(
      'Vérification de démonstration terminée. '
          'Aucun équipement réel n’a été analysé.',
    );
  }

  // ============================================================
  // PLANIFICATION UTILISATEUR
  // ============================================================

  Future<void> _createMaintenanceTask() async {
    final title = _taskTitleController.text.trim();

    if (title.length < 3) {
      _notify(
        'Saisis un titre d’au moins 3 caractères.',
        error: true,
      );
      return;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null || !mounted) return;

    final scheduledAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      _tasks.add(
        MaintenanceTask(
          id: 'MAINT-${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          scheduledAt: scheduledAt,
          status: 'Planifiée localement',
        ),
      );

      _taskTitleController.clear();
      _selectedTaskDate = null;
      _selectedTaskTime = null;
    });

    _tasks.sort(
          (a, b) => a.scheduledAt.compareTo(b.scheduledAt),
    );

    _notify('Maintenance planifiée localement.');
  }

  String _formatDateTime(DateTime value) {
    String two(int number) =>
        number.toString().padLeft(2, '0');

    return '${two(value.day)}/${two(value.month)}/${value.year} '
        'à ${two(value.hour)}:${two(value.minute)}';
  }

  // ============================================================
  // INTERFACE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B14),
        title: const Text(
          'SRE et opérations — démonstration',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF00E5FF),
          labelColor: const Color(0xFF00E5FF),
          unselectedLabelColor: Colors.blueGrey,
          tabs: const [
            Tab(text: 'Télémétrie'),
            Tab(text: 'Vast.ai'),
            Tab(text: 'Configurations'),
            Tab(text: 'Maintenance'),
            Tab(text: 'Journaux'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTelemetryTab(),
            _buildVastTab(),
            _buildBackupsTab(),
            _buildMaintenanceTab(),
            _buildLogsTab(),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // TÉLÉMÉTRIE
  // ------------------------------------------------------------

  Widget _buildTelemetryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Indicateurs de démonstration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ces valeurs sont générées localement pour illustrer '
                'l’interface. Elles ne proviennent d’aucun équipement.',
            style: TextStyle(color: Colors.white38),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _gauge(
                  'CPU simulé',
                  _cpuUsage,
                  '%',
                  Colors.cyanAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _gauge(
                  'Mémoire simulée',
                  _ramUsage,
                  '%',
                  Colors.purpleAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _gauge(
                  'Température simulée',
                  _temperature,
                  '°C',
                  Colors.orangeAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF131C2D),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Aucune alerte prédictive réelle n’est générée. '
                  'L’intégration d’un modèle prédictif nécessite des '
                  'données de télémétrie réelles et un service d’analyse.',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gauge(
      String title,
      double value,
      String unit,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131C2D),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: (value / 100).clamp(0.0, 1.0).toDouble(),
                  strokeWidth: 6,
                  backgroundColor: Colors.white10,
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${value.round()}$unit',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // VAST.AI
  // ------------------------------------------------------------

  Widget _buildVastTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Intégration Vast.ai',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'La clé reste dans la mémoire de cette session. '
                'Elle n’est pas enregistrée par cette interface.',
            style: TextStyle(color: Colors.white38),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _vastKeyController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Clé API Vast.ai',
              prefixIcon: Icon(Icons.key),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _vastLoading
                      ? null
                      : _loadVastInstances,
                  icon: const Icon(Icons.cloud_sync),
                  label: const Text('Mes instances'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _vastLoading
                      ? null
                      : _searchVastOffers,
                  icon: const Icon(Icons.search),
                  label: const Text('Rechercher'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _gpuNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'GPU recherché',
                    hintText: 'RTX 4090',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType:
                  const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Prix max (USD/h)',
                    hintText: '0.50',
                  ),
                ),
              ),
            ],
          ),
          if (_vastLoading) ...[
            const SizedBox(height: 20),
            const LinearProgressIndicator(),
          ],
          if (_vastError != null) ...[
            const SizedBox(height: 20),
            SelectableText(
              _vastError!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Mes instances Vast.ai',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_vastInstances.isEmpty)
            const Text(
              'Aucune instance affichée.',
              style: TextStyle(color: Colors.white38),
            )
          else
            for (final instance in _vastInstances)
              Card(
                color: const Color(0xFF131C2D),
                child: ListTile(
                  title: Text(
                    instance.label ?? 'Instance ${instance.id}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'ID : ${instance.id}\n'
                        'État : ${instance.actualStatus ?? "Inconnu"}\n'
                        'GPU : ${instance.gpuName ?? "Non renseigné"}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 24),
          const Text(
            'Offres disponibles',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_vastOffers.isEmpty)
            const Text(
              'Aucune offre affichée.',
              style: TextStyle(color: Colors.white38),
            )
          else
            for (final offer in _vastOffers)
              Card(
                color: const Color(0xFF131C2D),
                child: ListTile(
                  title: Text(
                    offer.gpuName ?? 'Offre ${offer.id}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Offre ID : ${offer.id}\n'
                        'Prix : ${offer.dphTotal?.toStringAsFixed(3) ?? "?"} \$/h\n'
                        'Fiabilité : '
                        '${offer.reliability == null ? "?" : (offer.reliability! * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 24),
          const Text(
            'Cette intégration lit les instances et recherche des offres. '
                'Elle ne crée, ne démarre et ne supprime aucune instance.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // CONFIGURATIONS
  // ------------------------------------------------------------

  Widget _buildBackupsTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Instantanés de démonstration',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Aucun dépôt GitOps, aucune signature et aucune '
              'restauration réelle ne sont implémentés.',
          style: TextStyle(color: Colors.white38),
        ),
        const SizedBox(height: 20),
        if (_backups.isEmpty)
          const Text(
            'Aucun instantané.',
            style: TextStyle(color: Colors.white38),
          )
        else
          for (final backup in _backups)
            Card(
              color: const Color(0xFF131C2D),
              child: ListTile(
                leading: Icon(
                  backup.markedStable
                      ? Icons.check_circle
                      : Icons.warning,
                  color: backup.markedStable
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                ),
                title: Text(
                  backup.id,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${backup.description}\n'
                      'Créé le ${_formatDateTime(backup.timestamp)}\n'
                      'Auteur : ${backup.author}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
      ],
    );
  }

  // ------------------------------------------------------------
  // MAINTENANCE
  // ------------------------------------------------------------

  Widget _buildMaintenanceTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Planifier une maintenance',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _taskTitleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Titre de la maintenance',
                  hintText:
                  'Exemple : vérification du point d’accès',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _createMaintenanceTask,
                  icon: const Icon(Icons.event_available),
                  label:
                  const Text('Choisir date, heure et planifier'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'La tâche est enregistrée dans la mémoire de '
                    'l’application. Elle n’est pas encore synchronisée '
                    'avec un calendrier externe.',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _tasks.isEmpty
              ? const Center(
            child: Text(
              'Aucune maintenance planifiée.',
              style: TextStyle(color: Colors.white38),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
            ),
            itemCount: _tasks.length,
            itemBuilder: (context, index) {
              final task = _tasks[index];

              return Card(
                color: const Color(0xFF131C2D),
                child: ListTile(
                  leading: const Icon(
                    Icons.event,
                    color: Color(0xFF00E5FF),
                  ),
                  title: Text(
                    task.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${_formatDateTime(task.scheduledAt)}\n'
                        '${task.status}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: 'Supprimer',
                    onPressed: () {
                      setState(() {
                        _tasks.remove(task);
                      });
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // JOURNAUX
  // ------------------------------------------------------------

  Widget _buildLogsTab() {
    final logs = _logs
        .where((log) => log.immutable == _showImmutableLogs)
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: CupertinoSlidingSegmentedControl<bool>(
            groupValue: _showImmutableLogs,
            backgroundColor: const Color(0xFF131C2D),
            thumbColor: const Color(0xFF3B82F6),
            children: const {
              true: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Événements',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
              false: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Notes d’équipe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            },
            onValueChanged: (value) {
              if (value == null) return;

              setState(() {
                _showImmutableLogs = value;
              });
            },
          ),
        ),
        Expanded(
          child: logs.isEmpty
              ? const Center(
            child: Text(
              'Aucun élément à afficher.',
              style: TextStyle(color: Colors.white38),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
            ),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];

              return Card(
                color: const Color(0xFF131C2D),
                child: ListTile(
                  title: Text(
                    log.event,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    '${log.id} • '
                        '${_formatDateTime(log.timestamp)}',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}