import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class AuditProcessManager {
  Process? _activeProcess;
  int? _currentPid;

  /// Lance un outil de diagnostic réseau et renvoie le flux en temps réel via des Callbacks
  Future<void> startTool(
      String executable,
      List<String> arguments,
      Function(String) onDataReceived,
      Function(int) onProcessComplete,
      ) async {
    try {
      debugPrint("🚀 [AUDIT] Lancement de $executable avec arguments protégés.");

      // SÉCURITÉ (DevSecOps) : runInShell: false est obligatoire.
      // Cela empêche l'OS d'interpréter des caractères spéciaux comme ';' ou '&&' (Anti-Injection).
      _activeProcess = await Process.start(executable, arguments, runInShell: false);
      _currentPid = _activeProcess?.pid;
      debugPrint("⚙️ [AUDIT] PID rattaché : $_currentPid");

      // Écoute et décodage du flux standard (stdout) ligne par ligne
      _activeProcess?.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        onDataReceived(line);
      });

      // Écoute du flux d'erreur (stderr) pour le debug
      _activeProcess?.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        onDataReceived("[INFO/WARNING] $line");
      });

      // Attente asynchrone de la fin du processus
      int exitCode = await _activeProcess!.exitCode;
      debugPrint("🏁 [AUDIT] Processus $_currentPid terminé (Code: $exitCode)");

      _cleanup();
      onProcessComplete(exitCode);

    } catch (e) {
      debugPrint("❌ [AUDIT] Erreur système lors de l'exécution : $e");
      onDataReceived("[ERREUR CRITIQUE] Impossible de lancer l'outil '$executable'.");
      onDataReceived("Vérifiez que l'outil est bien installé et accessible dans la variable d'environnement PATH de votre OS.");
      _cleanup();
      onProcessComplete(-1);
    }
  }

  /// Arrêt d'urgence propre (Kill Switch) déclenché par l'administrateur
  void killActiveProcess() {
    if (_activeProcess != null && _currentPid != null) {
      debugPrint("🛑 [AUDIT] Interruption forcée demandée pour le PID : $_currentPid");

      // SIGINT (Signal Interrupt) demande poliment au programme de s'arrêter (utile pour que Tshark sauvegarde ses buffers)
      bool success = _activeProcess!.kill(ProcessSignal.sigint);

      if (!success) {
        debugPrint("⚠️ [AUDIT] SIGINT ignoré, passage en SIGKILL (Fermeture brutale).");
        _activeProcess!.kill(ProcessSignal.sigkill);
      }
      _cleanup();
    } else {
      debugPrint("ℹ️ [AUDIT] Aucun processus actif à stopper.");
    }
  }

  void _cleanup() {
    _activeProcess = null;
    _currentPid = null;
  }
}