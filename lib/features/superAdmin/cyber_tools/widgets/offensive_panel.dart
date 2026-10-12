import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // Pour le Clipboard (Copier/Coller)
import 'package:google_fonts/google_fonts.dart';

// ==========================================
// 1. MODÈLE DE DONNÉES : OUTIL DE PENTEST
// ==========================================
class PentestTool {
  final String name;
  final String category;
  final String description;
  final IconData icon;
  final Map<String, String> commands;

  PentestTool({
    required this.name,
    required this.category,
    required this.description,
    required this.icon,
    required this.commands,
  });
}

// ==========================================
// 2. INTERFACE PRINCIPALE (ARSENAL RED TEAM)
// ==========================================
class OffensiveActionPage extends StatefulWidget {
  const OffensiveActionPage({super.key});

  @override
  State<OffensiveActionPage> createState() => _OffensiveActionPageState();
}

class _OffensiveActionPageState extends State<OffensiveActionPage> {
  // --- THÈME KALI MIXTE PREMIUM ---
  final Color kBgColor = const Color(0xFF05080F); // Noir Kali profond
  final Color kCardColor = const Color(0xFF0F172A); // Bleu nuit Ardoise
  final Color kRedAccent = const Color(0xFFFF2A55); // Rouge Red Team
  final Color kKaliBlue = const Color(0xFF268BD2); // Bleu Kali Linux
  final Color kTerminalGreen = const Color(0xFF00FF41); // Vert Matrix

  late final List<PentestTool> _tools;

  @override
  void initState() {
    super.initState();
    _tools = [
      // --- RECONNAISSANCE & SCANNING ---
      PentestTool(
          name: "Nmap", category: "Reconnaissance", icon: CupertinoIcons.search,
          description: "L'outil standard de l'industrie pour la découverte de réseaux et l'audit de sécurité (Scan de ports).",
          commands: {
            "Scan rapide (Ping Sweep)": "nmap -sn 192.168.1.0/24",
            "Scan agressif (OS, Versions, Scripts)": "nmap -A -T4 192.168.1.10",
            "Recherche de vulnérabilités": "nmap --script vuln 10.0.0.5",
          }
      ),
      PentestTool(
          name: "Nikto", category: "Vulnérabilités Web", icon: CupertinoIcons.globe,
          description: "Scanner de serveurs web qui recherche les fichiers dangereux, les versions obsolètes et les problèmes spécifiques.",
          commands: {
            "Scan standard d'une URL": "nikto -h http://192.168.1.50",
            "Scan avec évasion d'IDS": "nikto -h 10.0.0.5 -evasion 1",
          }
      ),
      PentestTool(
          name: "WPScan", category: "Vulnérabilités Web", icon: CupertinoIcons.doc_text_search,
          description: "Scanner de vulnérabilités en boîte noire spécialement conçu pour les environnements WordPress.",
          commands: {
            "Énumération des plugins vulnérables": "wpscan --url http://target.com -e vp",
            "Attaque force brute des utilisateurs": "wpscan --url http://target.com -e u --passwords wordlist.txt",
          }
      ),
      // --- EXPLOITATION & WEB ---
      PentestTool(
          name: "Metasploit", category: "Exploitation", icon: CupertinoIcons.flame_fill,
          description: "Le framework de développement et d'exécution d'exploits le plus puissant au monde.",
          commands: {
            "Lancer la console msf": "msfconsole -q",
            "Rechercher un exploit (ex: EternalBlue)": "search ms17-010",
            "Configurer un exploit": "use exploit/windows/smb/ms17_010_eternalblue\nset RHOSTS 192.168.1.10\nexploit",
          }
      ),
      PentestTool(
          name: "SQLmap", category: "Exploitation Web", icon: Icons.dns,
          description: "Outil d'automatisation redoutable pour détecter et exploiter les failles d'injection SQL (SQLi).",
          commands: {
            "Tester une URL vulnérable": "sqlmap -u \"http://target.com/page.php?id=1\" --dbs",
            "Dumper une base de données entière": "sqlmap -u \"http://target.com/page.php?id=1\" -D database_name --dump",
          }
      ),
      PentestTool(
          name: "Burp Suite", category: "Exploitation Web", icon: CupertinoIcons.shield_lefthalf_fill,
          description: "Plateforme intégrée pour réaliser des tests de sécurité web via un Proxy d'interception (MITM).",
          commands: {
            "Lancement standard (GUI)": "burpsuite",
            "Note d'architecture": "Configurez le proxy du navigateur cible sur 127.0.0.1:8080 pour intercepter les requêtes en clair.",
          }
      ),
      PentestTool(
          name: "Gobuster", category: "Énumération", icon: CupertinoIcons.folder_fill,
          description: "Outil ultra-rapide écrit en Go pour trouver des répertoires, fichiers et sous-domaines cachés.",
          commands: {
            "Fuzzing de répertoires web": "gobuster dir -u http://192.168.1.20 -w /usr/share/wordlists/dirb/common.txt",
            "Énumération de sous-domaines": "gobuster dns -d target.com -w /usr/share/wordlists/dns.txt",
          }
      ),
      // --- ATTAQUES DE MOTS DE PASSE ---
      PentestTool(
          name: "Hydra", category: "Force Brute", icon: CupertinoIcons.lock_open_fill,
          description: "Craqueur de connexion réseau massivement parallèle, supportant de nombreux protocoles (SSH, FTP, HTTP).",
          commands: {
            "Force brute SSH": "hydra -l admin -P rockyou.txt ssh://192.168.1.1",
            "Force brute formulaire Web": "hydra -L users.txt -P pass.txt 10.0.0.5 http-post-form \"/login.php:user=^USER^&pass=^PASS^:F=incorrect\"",
          }
      ),
      PentestTool(
          name: "John the Ripper", category: "Craquage Hash", icon: CupertinoIcons.lock_slash_fill,
          description: "Outil de cassage de mots de passe hors-ligne très réputé (Hash cracking).",
          commands: {
            "Casser un fichier contenant des hashes": "john --wordlist=rockyou.txt hashes.txt",
            "Afficher les mots de passe cassés": "john --show hashes.txt",
          }
      ),
      PentestTool(
          name: "Hashcat", category: "Craquage Hash", icon: CupertinoIcons.bolt_fill,
          description: "Le craqueur de mots de passe le plus rapide au monde, exploitant l'accélération GPU.",
          commands: {
            "Attaque par dictionnaire (MD5)": "hashcat -m 0 -a 0 hashes.txt rockyou.txt",
            "Attaque dictionnaire (WPA/WPA2)": "hashcat -m 22000 -a 0 handshake.hc22000 rockyou.txt",
          }
      ),
      // --- SNIFFING & SPOOFING ---
      PentestTool(
          name: "Wireshark", category: "Analyse de Paquets", icon: CupertinoIcons.waveform_path,
          description: "L'analyseur de protocole réseau le plus utilisé au monde. Utilise TShark pour la ligne de commande.",
          commands: {
            "Lancer l'interface GUI (Root)": "wireshark",
            "Capture CLI (TShark) sur port 80": "tshark -i eth0 -f \"tcp port 80\"",
          }
      ),
      PentestTool(
          name: "Responder", category: "Spoofing", icon: CupertinoIcons.radiowaves_right,
          description: "Empoisonneur LLMNR, NBT-NS et MDNS redoutable pour capturer des hashs NTLM sur les réseaux Windows.",
          commands: {
            "Lancer l'empoisonnement sur eth0": "responder -I eth0 -rdw",
          }
      ),
      // --- WIRELESS (SANS-FIL) ---
      PentestTool(
          name: "Aircrack-ng", category: "Wireless", icon: CupertinoIcons.wifi,
          description: "Suite complète pour auditer et évaluer la sécurité des réseaux Wi-Fi (802.11).",
          commands: {
            "Passer la carte en mode monitor": "airmon-ng start wlan0",
            "Capturer le trafic (Handshake)": "airodump-ng -c 6 --bssid 00:11:22:33:44:55 -w capture wlan0mon",
            "Casser la clé WPA/WPA2 hors-ligne": "aircrack-ng -w rockyou.txt capture-01.cap",
          }
      ),
    ];
  }

  // --- LE MODAL PREMIUM : CHEAT SHEET ---
  void _showToolCheatSheet(BuildContext context, PentestTool tool) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.80,
            padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 0),
            decoration: BoxDecoration(
              color: kCardColor.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: kRedAccent.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 40)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header du Modal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kRedAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: kRedAccent.withValues(alpha: 0.5)),
                            ),
                            child: Icon(tool.icon, color: kRedAccent, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tool.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: kKaliBlue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: kKaliBlue.withValues(alpha: 0.5))),
                                  child: Text(tool.category.toUpperCase(), style: TextStyle(color: kKaliBlue, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(CupertinoIcons.clear_circled_solid, color: Colors.blueGrey, size: 30), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Colors.white12, height: 1)),

                // 2. Description
                Text(tool.description, style: TextStyle(color: Colors.blueGrey[200], fontSize: 14, height: 1.5)),
                const SizedBox(height: 24),
                const Text("ARSENAL DE COMMANDES (CHEAT SHEET)", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                const SizedBox(height: 16),

                // 3. Liste des commandes (Terminaux interactifs)
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: tool.commands.length,
                    itemBuilder: (context, index) {
                      String key = tool.commands.keys.elementAt(index);
                      String command = tool.commands[key]!;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Titre de l'action
                            Row(
                              children: [
                                const Icon(Icons.code, color: Colors.blueGrey, size: 14,
                                const SizedBox(width: 8),
                                Expanded(child: Text(key, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Fenêtre de Terminal MacOS/Kali Style
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFF000000), // Vrai noir
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                boxShadow: [BoxShadow(color: kTerminalGreen.withValues(alpha: 0.05), blurRadius: 10)],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Barre supérieure du terminal (Boutons rouge/jaune/vert)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                      border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(CupertinoIcons.circle_fill, color: Colors.redAccent, size: 10), const SizedBox(width: 6),
                                            const Icon(CupertinoIcons.circle_fill, color: Colors.orangeAccent, size: 10), const SizedBox(width: 6),
                                            const Icon(CupertinoIcons.circle_fill, color: Colors.greenAccent, size: 10),
                                            const SizedBox(width: 12),
                                            Text("bash - kali", style: TextStyle(color: Colors.blueGrey[400], fontSize: 10, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        // 🚀 BOUTON COPIER
                                        GestureDetector(
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(text: command));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Row(
                                                    children: [
                                                      const Icon(CupertinoIcons.check_mark_circled_solid, color: Colors.white),
                                                      const SizedBox(width: 12),
                                                      Text("Payload copié : $tool.name", style: const TextStyle(fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                  backgroundColor: kTerminalGreen.withValues(alpha: 0.8),
                                                  behavior: SnackBarBehavior.floating,
                                                  duration: const Duration(seconds: 2),
                                                )
                                            );
                                          },
                                          child: Icon(CupertinoIcons.doc_on_clipboard_fill, color: kKaliBlue, size: 16),
                                        )
                                      ],
                                    ),
                                  ),
                                  // Code de la commande
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: RichText(
                                        text: TextSpan(
                                            style: GoogleFonts.jetBrainsMono(fontSize: 13, height: 1.5),
                                            children: [
                                              const TextSpan(text: "root@kali", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                              const TextSpan(text: ":", style: TextStyle(color: Colors.white)),
                                              const TextSpan(text: "~# ", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                                              TextSpan(text: command, style: TextStyle(color: kTerminalGreen)),
                                            ]
                                        )
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- EN-TÊTE RED TEAM (Bannière) ---
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kCardColor, kBgColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kRedAccent.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [BoxShadow(color: kRedAccent.withValues(alpha: 0.1), blurRadius: 40)],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: kRedAccent.withValues(alpha: 0.15), shape: BoxShape.circle, border: Border.all(color: kRedAccent.withValues(alpha: 0.5))),
                  child: Icon(CupertinoIcons.flame_fill, color: kRedAccent, size: 36),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("ARSENAL RED TEAM (KALI LINUX)", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      const SizedBox(height: 6),
                      Text("Bibliothèque de références tactiques (TTPs). Cliquez sur un outil pour afficher sa Cheat Sheet et copier les charges utiles (Payloads).", style: TextStyle(color: Colors.blueGrey[400], fontSize: 12, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // --- GRILLE DES OUTILS (Responsive) ---
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              childAspectRatio: 2.2, // Cartes un peu plus larges et compactes
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _tools.length,
            itemBuilder: (context, index) {
              final tool = _tools[index];
              return InkWell(
                onTap: () => _showToolCheatSheet(context, tool),
                borderRadius: BorderRadius.circular(16),
                splashColor: kRedAccent.withValues(alpha: 0.2),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kCardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    // Subtil effet de lueur au survol/tap
                    boxShadow: [BoxShadow(color: kRedAccent.withValues(alpha: 0.02), blurRadius: 10, spreadRadius: 2)],
                  ),
                  child: Row(
                    children: [
                      // Icône de l'outil
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                        child: Icon(tool.icon, color: kRedAccent, size: 24),
                      ),
                      const SizedBox(width: 16),
                      // Textes
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(tool.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Text(tool.category.toUpperCase(), style: TextStyle(color: kKaliBlue, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                          ],
                        ),
                      ),
                      // Flèche indicative
                      Icon(CupertinoIcons.chevron_right, color: Colors.blueGrey[700], size: 16),
                    ],
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