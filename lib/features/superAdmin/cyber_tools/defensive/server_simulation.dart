import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  // Liste de tous les administrateurs (consoles Flutter) connectés
  final List<WebSocketChannel> connectedClients = [];
  final Random random = Random();

  // Liste de fausses attaques pour simuler l'activité réseau
  final List<Map<String, dynamic>> attackTemplates = [
    {
      "title": "Brute-force SSH détecté (Hydra)",
      "target": "Routeur_Core_Linux",
      "severity": "CRITICAL",
      "severity_score": 9.2
    },
    {
      "title": "Scan de vulnérabilités Web (Nikto)",
      "target": "Console_Admin_Web",
      "severity": "WARNING",
      "severity_score": 5.4
    },
    {
      "title": "Tentative d'injection SQL sur l'API",
      "target": "Base_Donnees_IoT",
      "severity": "CRITICAL",
      "severity_score": 8.7
    },
    {
      "title": "Ping anormal détecté (Scan Nmap)",
      "target": "Passerelle_VPN",
      "severity": "INFO",
      "severity_score": 2.1
    },
    {
      "title": "Appareil IoT non autorisé connecté",
      "target": "Commutateur_Etage_1",
      "severity": "WARNING",
      "severity_score": 4.5
    }
  ];

  // Configuration du gestionnaire WebSocket[cite: 4]
  var handler = webSocketHandler((WebSocketChannel webSocket) {
    connectedClients.add(webSocket);
    print("💻 Une console d'administration Flutter vient de se connecter.");

    // Nettoyage lorsque la console se déconnecte[cite: 4]
    webSocket.stream.listen(
          (message) {},
      onDone: () {
        connectedClients.remove(webSocket);
        print("❌ Une console s'est déconnectée.");
      },
    );
  });

  // Démarrage du serveur sur le port 8080[cite: 4]
  var server = await io.serve(handler, '0.0.0.0', 8080);
  print('🚀 Serveur de sécurité en temps réel actif sur : ws://${server.address.address}:${server.port}');

  // Boucle de génération d'alertes en temps réel (toutes les 3 secondes)[cite: 4]
  Timer.periodic(const Duration(seconds: 3), (timer) {
    if (connectedClients.isEmpty) return;

    // Sélection aléatoire d'une attaque[cite: 4]
    final template = attackTemplates[random.nextInt(attackTemplates.length)];

    // Génération d'une IP source aléatoire pour le réalisme[cite: 4]
    final String randomIp = "192.168.1.${random.nextInt(254) + 1}";

    final Map<String, dynamic> alertPacket = {
      "title": template["title"],
      "source_ip": randomIp,
      "target": template["target"],
      "severity": template["severity"],
      "severity_score": template["severity_score"],
      "timestamp": DateTime.now().toIso8601String().substring(11, 19)
    };

    // Diffusion du paquet JSON à toutes les consoles Flutter connectées[cite: 4]
    final String jsonString = jsonEncode(alertPacket);
    for (var client in connectedClients) {
      client.sink.add(jsonString);
    }
    print("🚨 Alerte diffusée : ${template["title"]} depuis $randomIp");
  });
}