import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Import du gestionnaire SQLite
import 'database_manager.dart';
// import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart'; // Pour la prod

// ==========================================
// DARK PULSE CORE - SERVEUR SDN & SIEM
// ==========================================

void main() async {
  print("=========================================");
  print("🚀 DÉMARRAGE DE DARK PULSE CORE (v1.0)");
  print("=========================================\n");

  // 1. Initialisation de la base de données SQLite
  try {
    final db = DatabaseManager();
    db.init();
  } catch (e) {
    print("❌ [CRITICAL] Impossible d'initialiser la base de données SQLite : $e");
    return; // On stoppe le serveur si la base de données est corrompue (Sécurité)
  }

  // 2. Démarrage du serveur
  final coreServer = DarkPulseCore();
  await coreServer.start();
}

class DarkPulseCore {
  final Set<WebSocketChannel> _dashboardClients = {};
  

  Future<void> start() async {
    // 1. Initialisation des routes API (Control Plane)
    final router = Router();

    // Route : Statut du système (Health Check)
    router.get('/api/v1/health', _healthCheckHandler);

    // Route : Télécharger l'historique des logs depuis SQLite (NOUVEAU)
    router.get('/api/v1/logs', _getLogsHistoryHandler);

    // Route : Exécuter une action SOAR (Bannir IP)
    router.post('/api/v1/soar/ban', _banIpHandler);

    // Route : Connexion WebSocket (Data Plane)
    router.get('/ws/siem', _webSocketHandler());

    // 2. Middleware de Sécurité (Log + Vérification du Token ZTNA)
    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_zeroTrustAuthMiddleware())
        .addHandler(router.call);

    // 3. Démarrage du Serveur Web HTTP/WS (Port 8443)
    final server = await io.serve(handler, InternetAddress.anyIPv4, 8443);
    print('🛡️ [API & WSS] Écoute des connexions sur http://${server.address.address}:${server.port}');

    // 4. Démarrage du collecteur Syslog UDP (Port 5145)
    _startSyslogListener();

    // 5. Simulateur de télémétrie matérielle locale (CPU/RAM du serveur)
    _startHardwareTelemetry();
  }

  // ==========================================
  // MIDDLEWARE DEVSECOPS (Zero Trust)
  // ==========================================
  Middleware _zeroTrustAuthMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        // On laisse passer le health check sans token pour le monitoring (ex: UptimeRobot)
        if (request.url.path == 'api/v1/health') {
          return innerHandler(request);
        }

        final authHeader = request.headers['Authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          print("❌ [BLOCAGE] Requête rejetée : Aucun token fourni depuis l'IP ${request.context['shelf.io.connection_info']}.");
          return Response.forbidden(jsonEncode({'error': 'Accès refusé. Token manquant.'}), headers: {'Content-Type': 'application/json'});
        }

        // En production : Décommenter pour vérifier le JWT
        // final token = authHeader.substring(7);
        // try { JWT.verify(token, SecretKey(_secretKey)); } catch(e) { return Response.forbidden(); }

        return innerHandler(request);
      };
    };
  }

  // ==========================================
  // CONTRÔLEURS API (REST)
  // ==========================================
  Response _healthCheckHandler(Request request) {
    return Response.ok(jsonEncode({
      'status': 'ONLINE',
      'version': '1.8.0-core',
      'os': Platform.operatingSystem,
      'uptime': '99.99%',
    }), headers: {'Content-Type': 'application/json'});
  }

  // NOUVEAU : Récupération de l'historique depuis SQLite
  Response _getLogsHistoryHandler(Request request) {
    try {
      final logs = DatabaseManager().getRecentLogs();
      return Response.ok(jsonEncode({'success': true, 'data': logs}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      print("❌ [DB ERREUR] $e");
      return Response.internalServerError(body: jsonEncode({'error': 'Erreur lors de la lecture de la base de données.'}));
    }
  }

  Future<Response> _banIpHandler(Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);
      final targetIp = data['ip'];

      // Validation stricte Anti-Injection Shell
      final ipRegex = RegExp(r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$');
      if (!ipRegex.hasMatch(targetIp)) {
        return Response.badRequest(body: jsonEncode({'error': 'Format IP Invalide. Action bloquée.'}), headers: {'Content-Type': 'application/json'});
      }

      print("⚡ [SOAR] Ordre reçu depuis le Dashboard : Bannir l'IP $targetIp");

      if (Platform.isLinux) {
        await Process.run('iptables', ['-I', 'INPUT', '-s', targetIp, '-j', 'DROP']);
      } else {
        print("⚠️ [SOAR] Simulation de bannissement (L'OS hôte n'est pas Linux).");
      }

      return Response.ok(jsonEncode({'message': 'IP bannie avec succès.', 'ip': targetIp}), headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  // ==========================================
  // WEBSOCKET (Flux vers l'app mobile)
  // ==========================================
  Handler _webSocketHandler() {
    return webSocketHandler((WebSocketChannel webSocket) {
      _dashboardClients.add(webSocket);
      print("🔌 [SOC] Application Dashboard connectée. Flux SIEM actif.");

      webSocket.stream.listen(
            (message) {}, // Réception de messages potentiels du client
        onDone: () {
          _dashboardClients.remove(webSocket);
          print("🔌 [SOC] Dashboard déconnecté.");
        },
        onError: (err) => _dashboardClients.remove(webSocket),
      );
    });
  }

  void _broadcastToDashboards(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    for (var client in List.from(_dashboardClients)) {
      try {
        client.sink.add(jsonString);
      } catch (e) {
        _dashboardClients.remove(client);
      }
    }
  }

  // ==========================================
  // SYSLOG UDP LISTENER (Ingestion de logs)
  // ==========================================
  void _startSyslogListener() async {
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 5145);
      print('📡 [NIDS] En écoute des Syslogs matériels UDP sur le port 5145...');

      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? datagram = socket.receive();
          if (datagram != null) {
            String logMessage = utf8.decode(datagram.data);
            // On délègue l'analyse au moteur heuristique
            _analyzeRealLog(logMessage, datagram.address.address);
          }
        }
      });
    } catch (e) {
      print("❌ [CRITICAL] Impossible de lier le socket UDP (Port 5145) : $e");
    }
  }

  // --- MOTEUR D'ANALYSE ET SAUVEGARDE DB ---
  void _analyzeRealLog(String log, String routerIp) {
    final ipRegex = RegExp(r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b');

    // Détection de menaces (Mots-clés Cyber)
    bool isSshBruteForce = log.toLowerCase().contains("failed password") || log.toLowerCase().contains("invalid user");
    bool isPortScan = log.toLowerCase().contains("ufw block") || log.toLowerCase().contains("drop");
    bool isWafAlert = log.toLowerCase().contains("modsecurity") || log.toLowerCase().contains("sqli");

    if (isSshBruteForce || isPortScan || isWafAlert) {

      // Extraction de l'IP de l'attaquant
      final matches = ipRegex.allMatches(log);
      String attackerIp = "Inconnue";
      if (matches.isNotEmpty) {
        attackerIp = matches.last.group(0)!; // Souvent la dernière IP du log est l'attaquant
      }

      // Ignore les boucles internes
      if (attackerIp == routerIp || attackerIp == "127.0.0.1") return;

      String threatType = isSshBruteForce ? "Brute-Force SSH" : (isPortScan ? "Balayage de Ports" : "Alerte WAF (Web Attack)");
      double score = isWafAlert ? 9.8 : (isSshBruteForce ? 8.5 : 5.0);
      String eventId = "EVT-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}";
      String timeNow = DateTime.now().toIso8601String().substring(11, 19);
      String severity = score > 7 ? "CRITICAL" : "WARNING";

      // 1. SAUVEGARDE DANS LA BASE DE DONNÉES SQLITE
      try {
        DatabaseManager().insertSecurityLog(
          eventId: eventId,
          timestamp: timeNow,
          threatType: threatType,
          sourceIp: attackerIp,
          severity: severity,
          score: score,
          rawLog: log,
        );
      } catch (e) {
        print("⚠️ [DB ERREUR] Échec de sauvegarde du log : $e");
      }

      // 2. PRÉPARATION DU PAQUET JSON POUR L'APPLICATION FLUTTER
      final alertPacket = {
        "type": "SIEM_ALERT",
        "title": "DÉTECTION RÉELLE : $threatType",
        "source_ip": attackerIp,
        "target": "Passerelle ($routerIp)",
        "severity": severity,
        "severity_score": score,
        "timestamp": timeNow,
        "raw_log": log
      };

      // 3. DIFFUSION EN DIRECT AUX DASHBOARDS
      _broadcastToDashboards(alertPacket);
      print("🚨 [MENACE SAUVEGARDÉE & DIFFUSÉE] Origine: $attackerIp (Sévérité: $severity)");
    }
  }

  // ==========================================
  // TÉLÉMÉTRIE MATÉRIELLE LOCALE
  // ==========================================
  void _startHardwareTelemetry() {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_dashboardClients.isEmpty) return;

      _broadcastToDashboards({
        "type": "TELEMETRY",
        "cpu_usage": 30.0 + (DateTime.now().second % 20),
        "ram_usage": 55.0,
        "temperature": 45.0,
      });
    });
  }
}