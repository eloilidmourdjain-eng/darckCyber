import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart'; // Assurez-vous d'importer le package xterm / flutter_xterm selon votre configuration

// Structure d'une commande du dictionnaire mobile
class TerminalCommand {
  final String name;
  final String category;
  final String description;
  final String Function(List<String> args) simulate;

  TerminalCommand({
    required this.name,
    required this.category,
    required this.description,
    required this.simulate,
  });
}

class MobileTerminalView extends StatefulWidget {
  const MobileTerminalView({super.key});

  @override
  State<MobileTerminalView> createState() => _MobileTerminalViewState();
}

class _MobileTerminalViewState extends State<MobileTerminalView> {
  // Initialisation du contrôleur xterm pour le mode mobile
  final Terminal _terminal = Terminal();
  final TextEditingController _inputController = TextEditingController();

  // Dictionnaire complet des commandes embarquées sur Mobile
  final Map<String, TerminalCommand> _mobileCommandDictionary = {
    // 🌐 Administration Réseau
    'ping': TerminalCommand(
      name: 'ping',
      category: 'Réseau',
      description: 'Vérifie la connectivité réseau.',
      simulate: (args) => args.isEmpty
          ? '\r\nErreur: Veuillez spécifier une cible (ex: ping google.com)\r\n'
          : '\r\nPING ${args.first} 56(84) bytes of data.\r\n64 bytes from ${args.first}: icmp_seq=1 ttl=54 time=12.4 ms\r\n64 bytes from ${args.first}: icmp_seq=2 ttl=54 time=11.8 ms\r\n',
    ),
    'ifconfig': TerminalCommand(
      name: 'ifconfig',
      category: 'Réseau',
      description: 'Affiche les interfaces réseau.',
      simulate: (args) => '\r\neth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST> mtu 1500\r\n        inet 192.168.1.50  netmask 255.255.255.0  broadcast 192.168.1.255\r\n        rxqueuelen 1000  (Ethernet)\r\n\r\nlo: flags=73<UP,LOOPBACK,RUNNING> mtu 65536\r\n        inet 127.0.0.1  netmask 255.0.0.0\r\n',
    ),
    'curl': TerminalCommand(
      name: 'curl',
      category: 'Réseau',
      description: 'Envoie des requêtes HTTP/HTTPS.',
      simulate: (args) => args.isEmpty
          ? '\r\ncurl: try \'curl --help\' for more information\r\n'
          : '\r\n<!DOCTYPE html>\r\n<html>\r\n<head><title>200 OK</title></head>\r\n<body><h1>Connexion établie avec succès vers ${args.first}</h1></body>\r\n</html>\r\n',
    ),

    // 💻 Gestion Système
    'ls': TerminalCommand(
      name: 'ls',
      category: 'Système',
      description: 'Liste les fichiers du répertoire.',
      simulate: (args) => '\r\nDocuments/  Downloads/  darck_cyber_core/  config.env  secrets.db\r\n',
    ),
    'whoami': TerminalCommand(
      name: 'whoami',
      category: 'Système',
      description: 'Affiche l\'utilisateur connecté.',
      simulate: (args) => '\r\nroot_mobile_sandbox\r\n',
    ),
    'uname': TerminalCommand(
      name: 'uname',
      category: 'Système',
      description: 'Informations système.',
      simulate: (args) => '\r\nLinux darck-mobile-kernel 6.1.0-sandbox-arm64 #1 SMP PREEMPT_DYNAMIC\r\n',
    ),

    // ⚔️ Pentesting & Outils Offensifs (Mode Anticipé / Fallback Desktop)
    'nmap': TerminalCommand(
      name: 'nmap',
      category: 'Pentesting',
      description: 'Scanner de ports réseau.',
      simulate: (args) => '\r\n⚠️ Ce module (nmap) requiert un environnement Desktop.\r\nVeuillez installer Nmap sur votre PC ou basculer sur la version Desktop de DarckCyber pour l\'utiliser pleinement.\r\n',
    ),
    'sqlmap': TerminalCommand(
      name: 'sqlmap',
      category: 'Pentesting',
      description: 'Automatise les injections SQL.',
      simulate: (args) => '\r\n⚠️ Outil d\'injection SQL restreint en mode Sandbox mobile.\r\n',
    ),
    'msfconsole': TerminalCommand(
      name: 'msfconsole',
      category: 'Pentesting',
      description: 'Framework Metasploit.',
      simulate: (args) => '\r\n[!] Le chargement de Metasploit nécessite un démon système lourd.\r\nVeuillez exécuter cette commande sur votre station de travail principale.\r\n',
    ),

    // 🛡️ Cyberdéfense & Sécurité
    'iptables': TerminalCommand(
      name: 'iptables',
      category: 'Défense',
      description: 'Règles de pare-feu.',
      simulate: (args) => '\r\nChain INPUT (policy ACCEPT)\r\ntarget     prot opt source               destination         \r\nACCEPT     all  --  anywhere             anywhere             state RELATED,ESTABLISHED\r\n',
    ),
    'fail2ban': TerminalCommand(
      name: 'fail2ban',
      category: 'Défense',
      description: 'Statistiques du pare-feu applicatif.',
      simulate: (args) => '\r\nStatus\r\n|- Number of jail: 3\r\n`- Jails: sshd, httpd-auth, darck-api-trap\r\n',
    ),
  };

  @override
  void initState() {
    super.initState();
    _initTerminalWelcome();
  }

  void _initTerminalWelcome() {
    _terminal.write('DarckCyber Mobile Sandbox Security Shell [Version 2.5.0]\r\n');
    _terminal.write('Type \'help\' pour voir les commandes disponibles ou tapez directement votre instruction.\r\n\r\n');
    _terminal.write('root@darck-mobile:~# ');
  }

  void _handleSubmittedCommand(String fullLine) {
    String trimmed = fullLine.trim();
    if (trimmed.isEmpty) {
      _terminal.write('\r\nroot@darck-mobile:~# ');
      return;
    }

    List<String> parts = trimmed.split(' ');
    String command = parts.first;
    List<String> arguments = parts.sublist(1);

    if (command == 'clear') {
      _terminal.buffer.clear();
      _terminal.write('root@darck-mobile:~# ');
      return;
    }

    if (command == 'help') {
      _terminal.write('\r\nCommandes disponibles sur Mobile :\r\n');
      _mobileCommandDictionary.forEach((key, value) {
        _terminal.write(' - $key : ${value.description}\r\n');
      });
      _terminal.write('\r\nroot@darck-mobile:~# ');
      return;
    }

    if (_mobileCommandDictionary.containsKey(command)) {
      String output = _mobileCommandDictionary[command]!.simulate(arguments);
      _terminal.write(output);
    } else {
      _terminal.write('\r\nCommand \'$command\' not found. Tapez \'help\' pour la liste des commandes.\r\n');
    }

    _terminal.write('\r\nroot@darck-mobile:~# ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Terminal Mobile (Sécurisé)", style: TextStyle(color: Colors.white, fontSize: 14)),
        iconTheme: const IconThemeData(color: Color(0xFF38BDF8)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(8.0),
              child: TerminalView(_terminal),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Entrez une commande (ex: ping, ls, nmap)...",
                      hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                    onSubmitted: (value) {
                      _terminal.write(value);
                      _handleSubmittedCommand(value);
                      _inputController.clear();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF38BDF8), size: 20),
                  onPressed: () {
                    String value = _inputController.text;
                    _terminal.write(value);
                    _handleSubmittedCommand(value);
                    _inputController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}