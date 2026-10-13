import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart'; // Pour la prod

// ==========================================
// DARK PULSE CORE - SERVEUR SDN & SIEM
// ==========================================

void main() async {
  print("=========================================");
  print("🚀 DÉMARRAGE DE DARK PULSE CORE (v1.0)");
  print("=========================================\n");

  final coreServer = DarkPulseCore();
  await coreServer.start();
}

class DarkPulseCore {
  final Set<WebSocketChannel> _dashboardClients = {};
  final String _secretKey = "SUPER_SECRET_JWT_KEY_DEVSECOPS"; // À mettre dans un .env

  Future<void> start() async {
    // 1. Initialisation des routes API (Control Plane)
    final router = Router();

    // Route : Statut du système (Health Check)
    router.get('/api/v1/health', _healthCheckHandler);

    // Route : Exécuter une action SOAR (Bannir IP)
    router.post('/api/v1/soar/ban', _banIpHandler);

    // Route : Connexion WebSocket (Data Plane)
    router.get('/ws/siem', _webSocketHandler());

    // 2. Middleware de Sécurité (Log + Vérification du Token)
    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_zeroTrustAuthMiddleware())
        .addHandler(router.call);

    // 3. Démarrage du Serveur Web HTTP/WS (Port 8443)
    final server = await io.serve(handler, InternetAddress.anyIPv4, 8443);
    print('🛡️ [API & WSS] Écoute sur http://${server.address.address}:${server.port}');

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
        // On laisse passer la route de health check sans token
        if (request.url.path == 'api/v1/health') {
          return innerHandler(request);
        }

        final authHeader = request.headers['Authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          print("❌ [BLOCAGE] Requête rejetée : Aucun token fourni (${request.context['shelf.io.connection_info']}).");
          return Response.forbidden(jsonEncode({'error': 'Accès refusé. Token manquant.'}));
        }

        // final token = authHeader.substring(7);
        // Ici en production : vérifier le JWT via dart_jsonwebtoken
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

  Future<Response> _banIpHandler(Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload);
      final targetIp = data['ip'];

      // Validation stricte Anti-Injection
      final ipRegex = RegExp(r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$');
      if (!ipRegex.hasMatch(targetIp)) {
        return Response.badRequest(body: jsonEncode({'error': 'Format IP Invalide.'}));
      }

      print("⚡ [SOAR] Ordre reçu : Bannir l'IP $targetIp");

      // Exécution de la commande système natif (iptables ou ufw)
      // Note: Nécessite des droits root sur la machine hôte.
      if (Platform.isLinux) {
        await Process.run('iptables', ['-I', 'INPUT', '-s', targetIp, '-j', 'DROP']);
      } else {
        print("⚠️ [SOAR] Simulation de bannissement (Non-Linux OS).");
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
      print("🔌 [SOC] Application Mobile connectée. Début de transmission des logs.");

      webSocket.stream.listen(
            (message) {}, // On peut recevoir des messages de l'app si besoin
        onDone: () => _dashboardClients.remove(webSocket),
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
  // SYSLOG LISTENER (Écoute les vrais routeurs)
  // ==========================================
  void _startSyslogListener() async {
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 5145);
      print('📡 [NIDS] En écoute des Syslogs UDP sur le port 5145...');

      final ipRegex = RegExp(r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b');

      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram? datagram = socket.receive();
          if (datagram != null) {
            String log = utf8.decode(datagram.data);

            // Si le log contient un mot suspect, on génère une alerte
            if (log.toLowerCase().contains('failed') || log.toLowerCase().contains('drop')) {
              final match = ipRegex.firstMatch(log);
              String attackerIp = match != null ? match.group(0)! : 'Unknown';

              _broadcastToDashboards({
                "type": "SIEM_ALERT",
                "title": "Alerte de Sécurité Syslog",
                "source_ip": attackerIp,
                "severity": "CRITICAL",
                "severity_score": 8.5,
                "timestamp": DateTime.now().toIso8601String().substring(11, 19)
              });
            }
          }
        }
      });
    } catch (e) {
      print("❌ [ERREUR] Impossible de lier le socket UDP : $e");
    }
  }

  // ==========================================
  // TÉLÉMÉTRIE MATÉRIELLE LOCALE
  // ==========================================
  void _startHardwareTelemetry() {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_dashboardClients.isEmpty) return;

      // Ici, on pourrait lire /proc/stat sur Linux pour avoir la vraie charge CPU
      _broadcastToDashboards({
        "type": "TELEMETRY",
        "cpu_usage": 30.0 + (DateTime.now().second % 20),
        "ram_usage": 55.0,
        "temperature": 45.0,
      });
    });
  }
}