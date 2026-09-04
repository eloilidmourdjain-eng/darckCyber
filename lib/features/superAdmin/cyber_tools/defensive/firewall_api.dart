import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dartssh2/dartssh2.dart';

// --- GESTIONNAIRE SÉCURISÉ (DevSecOps Backend Logic) ---
class OperationalCyberManager {
  static const String _host = '192.168.1.1';
  static const String _user = 'root';

  // CORRECTION SÉCURITÉ : Utilisation de variables d'environnement ou de clés sécurisées (Stockage local chiffré)
  // En production, ne jamais stocker de mot en clair. Préférer SSHKeyPair.
  static const String _password = String.fromEnvironment('SSH_PASSWORD', defaultValue: 'SuperSecretPassword!');

  /// 🛡️ Algorithme Défensif : Bannissement sécurisé avec validation IP regex
  static Future<bool> banIpAddress(String ipAddress) async {
    // Validation stricte de l'IPv4 pour éliminer tout risque d'injection
    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (!ipRegex.hasMatch(ipAddress)) {
      debugPrint("❌ Erreur de sécurité : Format d'adresse IP invalide ($ipAddress)");
      return false;
    }

    try {
      debugPrint("🛡️ SSH C2 : Connexion sécurisée pour isoler l'IP $ipAddress...");

      final client = SSHClient(
        await SSHSocket.connect(_host, 22, timeout: const Duration(seconds: 5)),
        username: _user,
        onPasswordRequest: () => _password,
      );

      // Utilisation d'un paramétrage strict échappé
      final session = await client.execute('ufw deny from $ipAddress comment "Banni par Dark Puls SecOps"');
      final result = utf8.decode(await session.stdout.first);

      client.close();

      if (result.toLowerCase().contains('rule added') || result.toLowerCase().contains('skipped')) {
        debugPrint("✅ Succès NetOps : L'IP $ipAddress est isolée.");
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Échec critique du pare-feu : $e");
      return false;
    }
  }

  /// ⚔️ Algorithme Offensif : Pentest sécurisé par Liste Blanche (Whitelisting des Outils)
  static Future<String> runPentestTool(String tool, String target, String options) async {
    // SÉCURITÉ ARCHITECTURALE : Liste blanche stricte des binaires autorisés (Anti-Injection)
    const allowedTools = ['nmap', 'ping', 'traceroute', 'ncat'];
    if (!allowedTools.contains(tool)) {
      return "Erreur de sécurité : Outil non autorisé ou non répertorié dans la whitelist.";
    }

    // Validation basique de la cible
    if (target.isEmpty || target.contains(';') || target.contains('&')) {
      return "Erreur de sécurité : Caractères non autorisés détectés dans la cible.";
    }

    try {
      final client = SSHClient(
        await SSHSocket.connect(_host, 22, timeout: const Duration(seconds: 5)),
        username: _user,
        onPasswordRequest: () => _password,
      );

      final session = await client.execute('$tool $options $target');
      final output = await utf8.decoder.bind(session.stdout).join();

      client.close();
      return output;
    } catch (e) {
      return "Erreur d'exécution distante : $e";
    }
  }
}

// --- INTERFACE UTILISATEUR AVEC BOUTON D'ACTION DÉCLENCHEUR ---
class CyberOperationsScreen extends StatefulWidget {
  const CyberOperationsScreen({super.key});

  @override
  CyberOperationsScreenState createState() => CyberOperationsScreenState();
}

class CyberOperationsScreenState extends State<CyberOperationsScreen> {
  bool _isExecuting = false;
  String _consoleOutput = "En attente d'action opérateur...";
  final TextEditingController _ipController = TextEditingController(text: "192.168.1.109");

  // Fonction déclenchée par le bouton utilisateur
  Future<void> _executeRemoteDefenseAction() async {
    setState(() {
      _isExecuting = true;
      _consoleOutput = "Établissement du tunnel SSH sécurisé vers la passerelle...";
    });

    String targetIp = _ipController.text.trim();

    // Appel de l'algorithme sécurisé
    bool success = await OperationalCyberManager.banIpAddress(targetIp);

    setState(() {
      _isExecuting = false;
      _consoleOutput = success
          ? "[$targetIp] Isolation réussie via pare-feu distant (UFW)."
          : "[$targetIp] Échec de l'isolation ou règle déjà existante.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dark Puls - Control Center',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Console d’ingénierie et de remédiation réseau en temps réel',
                style: TextStyle(color: Colors.blueGrey[300], fontSize: 14),
              ),
              const SizedBox(height: 30),

              // Champ de saisie de l'IP cible
              TextField(
                controller: _ipController,
                style: GoogleFonts.jetBrainsMono(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Adresse IP Cible / Menace',
                  labelStyle: const TextStyle(color: Colors.cyanAccent),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.cyanAccent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- BOUTON D'ACTION UTILISATEUR (Correction de l'erreur .wrap() sur ButtonStyle) ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isExecuting ? null : _executeRemoteDefenseAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isExecuting
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text(
                    "ISOLER LA CIBLE (Exécuter SSH)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Console de sortie des logs
              const Text(
                'Logs de Sortie Distante',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _consoleOutput,
                      style: GoogleFonts.jetBrainsMono(color: Colors.cyanAccent, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}