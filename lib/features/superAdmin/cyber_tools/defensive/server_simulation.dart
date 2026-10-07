import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  final Set<WebSocketChannel> dashboardClients = {};

  // ========================================================
  // 1. SERVEUR WEBSOCKET (Pour envoyer les alertes à Flutter)
  // ========================================================
  var wsHandler = webSocketHandler((WebSocketChannel webSocket) {
    dashboardClients.add(webSocket);
    debugPrint("🔌 [C2-NODE] Application Dashboard Dark Pulse connectée.");

    webSocket.stream.listen(
          (message) {},
      onDone: () => dashboardClients.remove(webSocket),
      onError: (err) => dashboardClients.remove(webSocket),
    );
  });

  final wsServer = await io.serve(wsHandler, '0.0.0.0', 8080);
  debugPrint('🚀 [SIEM] WebSocket actif sur le port ${wsServer.port}');

  // ========================================================
  // 2. SERVEUR SYSLOG UDP RÉEL (Écoute les vrais routeurs)
  // ========================================================
  // Port 5145 utilisé pour éviter l'obligation d'être root (le port Syslog par défaut est 514)
  final int syslogPort = 5145;

  try {
    RawDatagramSocket syslogSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, syslogPort);
    debugPrint('🛡️ [SIEM] Écoute des trames Syslog UDP réelles sur le port $syslogPort...');

    // Moteur d'expressions régulières (Regex) pour l'analyse Forensics
    final ipRegex = RegExp(r'\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b');

    // Écoute des paquets réseaux entrants
    syslogSocket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? datagram = syslogSocket.receive();
        if (datagram != null) {
          String logMessage = utf8.decode(datagram.data);
          _analyzeRealLog(logMessage, datagram.address.address, dashboardClients, ipRegex);
        }
      }
    });
  } catch (e) {
    debugPrint("❌ [CRITICAL] Échec de la liaison UDP Syslog : $e");
  }
}

// --- MOTEUR D'ANALYSE HEURISTIQUE (IA BAsique) ---
void _analyzeRealLog(String log, String routerIp, Set<WebSocketChannel> clients, RegExp ipRegex) {
  // 1. Détection des signatures d'attaques
  bool isSshBruteForce = log.contains("Failed password") || log.contains("Invalid user");
  bool isPortScan = log.contains("UFW BLOCK") || log.contains("DROP");
  bool isWafAlert = log.contains("ModSecurity") || log.contains("SQLi") || log.contains("XSS");

  if (isSshBruteForce || isPortScan || isWafAlert) {
    // 2. Extraction de l'IP de l'attaquant
    final matches = ipRegex.allMatches(log);
    String attackerIp = "Inconnue";

    // Souvent, la dernière IP dans le log est celle de l'attaquant
    if (matches.isNotEmpty) {
      attackerIp = matches.last.group(0)!;
    }

    // On ignore le log si c'est notre propre routeur qui parle
    if (attackerIp == routerIp || attackerIp == "127.0.0.1") return;

    String threatType = isSshBruteForce ? "Brute-Force SSH" : (isPortScan ? "Balayage Pare-feu (Port Scan)" : "Alerte WAF (Web Attack)");
    double score = isWafAlert ? 9.8 : (isSshBruteForce ? 8.5 : 5.0);

    // 3. Création du paquet d'alerte
    final alertPacket = {
      "title": "DÉTECTION RÉELLE : $threatType",
      "source_ip": attackerIp,
      "target": "Passerelle ($routerIp)",
      "severity": score > 7 ? "CRITICAL" : "WARNING",
      "severity_score": score,
      "timestamp": DateTime.now().toIso8601String().substring(11, 19),
      "raw_log": log // On garde la preuve Forensics
    };

    final jsonString = jsonEncode(alertPacket);

    // 4. Diffusion immédiate aux dashboards Flutter
    for (var client in List.from(clients)) {
      client.sink.add(jsonString);
    }
    debugPrint("🚨 [MENACE DÉTECTÉE] Origine: $attackerIp -> Cible: $routerIp");
  }
}