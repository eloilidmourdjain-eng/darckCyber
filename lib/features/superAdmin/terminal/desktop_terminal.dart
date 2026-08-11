import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'package:flutter_pty/flutter_pty.dart';

class DesktopTerminalView extends StatefulWidget {
  const DesktopTerminalView({super.key});

  @override
  State<DesktopTerminalView> createState() => _DesktopTerminalViewState();
}

class _DesktopTerminalViewState extends State<DesktopTerminalView> {
  late Terminal _terminal;
  late Pty _pty;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initDesktopPty();
  }

  void _initDesktopPty() {
    _terminal = Terminal();

    String executable;
    List<String> arguments = [];

    if (Platform.isWindows) {
      executable = 'powershell.exe';
    } else if (Platform.isMacOS || Platform.isLinux) {
      executable = Platform.environment['SHELL'] ?? '/bin/bash';
    } else {
      executable = '/bin/sh';
    }

    try {
      _pty = Pty.start(
        executable,
        arguments: arguments,
        columns: 80,
        rows: 24,
      );

      _pty.output.cast<List<int>>().listen((data) {
        _terminal.write(String.fromCharCodes(data));
      });

      // Interception des commandes envoyées par l'utilisateur
      _terminal.onOutput = (data) {
        // Si l'utilisateur valide une ligne (touche Entrée / \r)
        if (data.contains('\r') || data.contains('\n')) {
          // Vous pouvez ici parser la ligne courante si besoin
        }
        _pty.write(const Utf8Encoder().convert(data));
      };

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      _terminal.write('Erreur lors du lancement du PTY natif : $e\r\n');
    }
  }

  /// 🛠️ Middleware : Vérifie si un binaire existe sur la machine hôte
  Future<bool> _checkCommandExists(String commandName) async {
    try {
      String checker = Platform.isWindows ? 'where' : 'which';
      ProcessResult result = await Process.run(checker, [commandName]);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// 🚀 Intercepteur intelligent avant transmission au shell
  void handleDesktopInput(String inputLine) async {
    List<String> parts = inputLine.trim().split(' ');
    if (parts.isEmpty || parts.first.isEmpty) return;

    String command = parts.first;

    // Liste des outils critiques à surveiller
    List<String> monitoredTools = ['docker', 'git', 'nmap', 'kubectl', 'node'];

    if (monitoredTools.contains(command)) {
      bool exists = await _checkCommandExists(command);
      if (!exists) {
        // Outil manquant : Affichage de l'assistant d'installation visuel
        _showInstallationWizard(command);
        return;
      }
    }

    // Si l'outil existe ou n'est pas surveillé, on l'envoie au vrai PTY
    _pty.write(const Utf8Encoder().convert('$inputLine\n'));
  }

  /// 🎨 Assistant d'installation visuel en cas d'absence de l'outil
  void _showInstallationWizard(String missingCommand) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            const SizedBox(width: 8),
            Text("Outil '$missingCommand' introuvable", style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(
          "Le binaire '$missingCommand' n'est pas détecté dans les variables d'environnement de votre système (${Platform.operatingSystem}).\n\nVoulez-vous lancer l'assistant d'installation automatique ?",
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
            onPressed: () {
              Navigator.pop(context);
              _terminal.write("\r\n[Assistant] Installation automatique de $missingCommand en cours...\r\n");
              // Exemple : Lancer winget ou apt selon l'OS en arrière-plan
            },
            child: const Text("Installer maintenant", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _pty.kill();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          "Console Native Desktop (${Platform.operatingSystem.toUpperCase()})",
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF38BDF8)),
      ),
      body: _isInitialized
          ? Container(
        color: Colors.black,
        padding: const EdgeInsets.all(8.0),
        child: TerminalView(_terminal),
      )
          : const Center(
        child: Text(
          "Initialisation du shell natif en cours...",
          style: TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
        ),
      ),
    );
  }
}