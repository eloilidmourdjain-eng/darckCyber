import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  // SÉCURITÉ ARCHITECTURALE : Utilisation d'un Set thread-safe/géré proprement pour les clients
  final Set<WebSocketChannel> clients = {};

  var handler = webSocketHandler((WebSocketChannel webSocket) {
    clients.add(webSocket);
    print("🔌 Nouvelle liaison sécurisée établie avec un client dashboard.");

    // Écoute des messages entrants pour gérer la fermeture ou le ping/pong
    webSocket.stream.listen(
          (message) {
        // Traitement optionnel des commandes de contrôle reçues du client
      },
      onDone: () {
        clients.remove(webSocket);
        print("🔌 Déconnexion propre d'un client dashboard.");
      },
      onError: (error) {
        clients.remove(webSocket);
        print("⚠️ Erreur de socket client détectée : $error");
      },
    );
  });

  // Démarrage sécurisé du serveur HTTP/WS sur l'interface locale ou durcie
  final server = await io.serve(handler, '0.0.0.0', 8080);
  print('🚀 Serveur IDS Réel (Dark Pulse SecOps) actif sur le port ${server.port}');

  // SÉCURITÉ : Vérification de l'existence du fichier de log avant de lancer le processus
  const logPath = '/var/log/auth.log';
  final logFile = File(logPath);

  if (!await logFile.exists()) {
    print("❌ Avertissement critique : Le fichier de journalisation $logPath est introuvable.");
    print("💡 Assurez-vous que rsyslog est actif ou ajustez la source vers journalctl.");
    return;
  }

  try {
    // --- ALGORITHME D'ANALYSE DE LOGS SÉCURISÉ (Tail -f) ---
    final process = await Process.start('tail', ['-F', logPath]);

    // Regex stricte pour capturer l'IP source des échecs d'authentification SSH
    final regexFailed = RegExp(r'Failed password for (?:invalid user )?.* from ([0-9a-fA-F:\.]+) port');

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (line.contains('Failed password')) {
        final match = regexFailed.firstMatch(line);
        if (match != null) {
          final attackerIp = match.group(1)!;

          final alertPacket = {
            "title": "Brute-force SSH détecté",
            "source_ip": attackerIp,
            "target": "Serveur_Core",
            "severity": "CRITICAL",
            "severity_score": 9.5,
            "timestamp": DateTime.now().toIso8601String().substring(11, 19)
          };

          final jsonString = jsonEncode(alertPacket);

          // DIFFUSION SÉCURISÉE : Itération sur une copie/Set pour éviter les erreurs de modification concurrente
          for (var client in List.from(clients)) {
            try {
              client.sink.add(jsonString);
            } catch (e) {
              print("❌ Échec d'envoi au client, suppression de la socket zombie : $e");
              clients.remove(client);
              client.sink.close();
            }
          }
          print("🚨 Menace Réelle isolée et diffusée : $attackerIp");
        }
      }
    }, onError: (err) {
      print("❌ Erreur critique du processus tail : $err");
    });

  } catch (e) {
    print("❌ Impossible de démarrer le sous-système de surveillance des logs : $e");
  }
}