import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:darck_puls/features/superAdmin/models/honeypot_alert.dart';

class HoneypotMonitorWidget extends StatefulWidget {
  /// Origine du backend, sans /api/honeypot/alerts.
  /// Exemple : http://ADRESSE_KALI:PORT_REEL
  final String apiBaseUrl;

  /// Jeton fourni par ton système de session, si nécessaire.
  final String? accessToken;

  /// Simple contrôle de présentation.
  /// Le backend doit aussi vérifier les droits.
  final bool canBlock;

  final Duration pollingInterval;

  HoneypotMonitorWidget({
    super.key,
    required this.apiBaseUrl,
    this.accessToken,
    this.canBlock = false,
    Duration? pollingInterval,
  })  : assert(
  pollingInterval == null ||
      pollingInterval.inSeconds >= 5,
  ),
        pollingInterval =
            pollingInterval ?? const Duration(seconds: 10);
  @override
  State<HoneypotMonitorWidget> createState() =>
      _HoneypotMonitorWidgetState();
}

class _HoneypotMonitorWidgetState
    extends State<HoneypotMonitorWidget> {
  final http.Client _client = http.Client();

  Timer? _timer;

  List<HoneypotAlert> _alerts = [];
  final Set<String> _hiddenIds = {};

  bool _fetching = false;
  bool _blockBusy = false;
  bool _disposed = false;

  int _generation = 0;

  String? _error;
  String? _warning;
  DateTime? _lastSuccess;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void didUpdateWidget(covariant HoneypotMonitorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final sourceChanged =
        oldWidget.apiBaseUrl != widget.apiBaseUrl ||
            oldWidget.accessToken != widget.accessToken;

    if (sourceChanged) {
      // Ignore les réponses provenant de l'ancienne source.
      _generation++;

      _alerts = [];
      _hiddenIds.clear();
      _lastSuccess = null;
      _error = null;
      _warning = null;
    }

    if (sourceChanged ||
        oldWidget.pollingInterval != widget.pollingInterval) {
      _startPolling();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _timer?.cancel();
    _client.close();
    super.dispose();
  }

  void _startPolling() {
    _timer?.cancel();

    unawaited(_fetchAlerts());

    _timer = Timer.periodic(widget.pollingInterval, (_) {
      unawaited(_fetchAlerts());
    });
  }

  Uri _endpoint(String path) {
    final base = Uri.tryParse(widget.apiBaseUrl.trim());

    if (base == null ||
        !base.hasAuthority ||
        base.host.isEmpty ||
        (base.scheme != 'http' && base.scheme != 'https') ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment ||
        (base.path.isNotEmpty && base.path != '/')) {
      throw const FormatException(
        'apiBaseUrl doit être une origine HTTP/HTTPS, '
            'sans chemin ni identifiants.',
      );
    }

    return base.replace(path: path);
  }

  Map<String, String> _headers({bool jsonBody = false}) {
    final token = widget.accessToken?.trim();

    return {
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  String _httpError(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Authentification requise ou session expirée.';
      case 403:
        return 'Accès refusé par le backend.';
      case 404:
        return 'Route API introuvable. Vérifie l’URL et le backend.';
      default:
        return 'Le backend a répondu HTTP $statusCode.';
    }
  }

  List<dynamic> _extractRows(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map<String, dynamic> &&
        decoded['alerts'] is List) {
      return decoded['alerts'] as List;
    }

    throw const FormatException(
      'Format attendu : une liste JSON ou {"alerts": [...]}.',
    );
  }

  Future<void> _fetchAlerts() async {
    if (_disposed || _fetching) return;

    final generation = _generation;

    setState(() {
      _fetching = true;
    });

    try {
      final response = await _client
          .get(
        _endpoint('/api/honeypot/alerts'),
        headers: _headers(),
      )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        throw Exception(_httpError(response.statusCode));
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final rows = _extractRows(decoded);

      final byId = <String, HoneypotAlert>{};
      int rejected = 0;

      for (final row in rows) {
        try {
          if (row is! Map<String, dynamic>) {
            throw const FormatException('Événement non objet.');
          }

          final alert = HoneypotAlert.fromJson(row);
          byId[alert.id] = alert;
        } catch (_) {
          rejected++;
        }
      }

      final parsed = byId.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (!mounted || generation != _generation) return;

      setState(() {
        _alerts = parsed;
        _lastSuccess = DateTime.now();
        _error = null;
        _warning = rejected == 0
            ? null
            : '$rejected événement(s) rejeté(s) : '
            'champs ou dates incompatibles avec le modèle.';
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;

      setState(() {
        _error = e is TimeoutException
            ? 'Délai dépassé lors de la lecture des alertes.'
            : 'Lecture impossible : $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _fetching = false;
        });
      }
    }
  }

  void _notify(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _blockAttacker(HoneypotAlert alert) async {
    if (!widget.canBlock || _blockBusy) return;

    final generation = _generation;

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la demande de blocage'),
        content: Text(
          'Cible : ${alert.ipAddress}\n'
              'Événement : ${alert.id}\n\n'
              'Cette opération peut affecter des communications légitimes. '
              'Le backend décide du périmètre et vérifie les autorisations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Envoyer la demande'),
          ),
        ],
      ),
    );

    if (approved != true ||
        !mounted ||
        generation != _generation ||
        !widget.canBlock) {
      return;
    }

    setState(() {
      _blockBusy = true;
    });

    try {
      final response = await _client
          .post(
        _endpoint('/api/honeypot/block'),
        headers: _headers(jsonBody: true),
        body: jsonEncode({
          // Contrat conservé de ton code initial.
          'ip_address': alert.ipAddress,
          'user_id': alert.userId,
        }),
      )
          .timeout(const Duration(seconds: 10));

      if (!mounted || generation != _generation) return;

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        _notify(
          'Le backend a accepté la demande '
              '(HTTP ${response.statusCode}). '
              'L’application effective du blocage reste à vérifier.',
        );

        await _fetchAlerts();
      } else {
        _notify(_httpError(response.statusCode));
      }
    } on TimeoutException {
      if (generation != _generation) return;

      _notify(
        'Réponse non reçue : le résultat du blocage est inconnu. '
            'Vérifie le backend avant de renvoyer une demande.',
      );
    } catch (e) {
      if (generation != _generation) return;

      _notify(
        'Communication interrompue : $e. '
            'Vérifie l’état de la demande côté backend.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _blockBusy = false;
        });
      }
    }
  }

  Widget _alertCard(HoneypotAlert alert) {
    return Card(
      color: const Color(0xFF263449),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alert.triggerType,
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              'ID : ${alert.id}\n'
                  'IP source : ${alert.ipAddress}\n'
                  'Empreinte : ${alert.deviceFingerprint}\n'
                  'Utilisateur déclaré : ${alert.userId}\n'
                  'Date locale : ${alert.timestamp.toLocal()}\n'
                  'Port : ${alert.targetPort ?? "Non renseigné"}\n'
                  'Protocole : ${alert.protocol ?? "Non renseigné"}\n'
                  'Gravité : ${alert.severity ?? "Non renseignée"}\n'
                  'Tentatives : ${alert.attemptCount ?? "Non renseigné"}\n'
                  'État : ${alert.status ?? "Non renseigné"}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _hiddenIds.add(alert.id);
                    });
                  },
                  child: const Text('Masquer localement'),
                ),
                OutlinedButton(
                  onPressed: widget.canBlock && !_blockBusy
                      ? () => _blockAttacker(alert)
                      : null,
                  child: const Text('Demander le blocage'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleAlerts = _alerts
        .where((alert) => !_hiddenIds.contains(alert.id))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.security,
                color: Colors.orangeAccent,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'SURVEILLANCE HONEYPOT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Actualiser',
                onPressed: _fetching
                    ? null
                    : () => unawaited(_fetchAlerts()),
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24),
          Text(
            'Interrogation toutes les '
                '${widget.pollingInterval.inSeconds} secondes.',
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 6),
          Text(
            _lastSuccess == null
                ? 'Aucune récupération réussie pour le moment.'
                : 'Dernière récupération : '
                '${_lastSuccess!.toLocal()}',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
          if (_fetching) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            SelectableText(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const Text(
              'Les éventuels résultats précédents sont conservés.',
              style: TextStyle(color: Colors.white60),
            ),
          ],
          if (_warning != null) ...[
            const SizedBox(height: 12),
            Text(
              _warning!,
              style: const TextStyle(color: Colors.orangeAccent),
            ),
          ],
          if (_hiddenIds.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() => _hiddenIds.clear());
              },
              child: const Text('Réafficher les alertes masquées'),
            ),
          const SizedBox(height: 12),
          if (visibleAlerts.isEmpty)
            Text(
              _lastSuccess == null
                  ? 'Aucune donnée exploitable reçue.'
                  : _alerts.isEmpty
                  ? 'Aucune alerte valide dans la dernière réponse. '
                  'Cela ne démontre pas que le réseau est sécurisé.'
                  : 'Toutes les alertes sont masquées localement.',
              style: const TextStyle(color: Colors.white70),
            ),
          for (final alert in visibleAlerts) _alertCard(alert),
          if (!widget.canBlock) ...[
            const SizedBox(height: 12),
            const Text(
              'Blocage désactivé dans cette vue.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}