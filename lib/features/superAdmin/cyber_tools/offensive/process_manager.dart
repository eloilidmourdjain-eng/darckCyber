import 'dart:io';

class OffensiveProcessManager {
  Process? _activeProcess;
  int? _currentPid;

  /// Lance une commande offensive et mémorise son PID pour un arrêt d'urgence
  Future<void> startTool(String executable, List<String> arguments, Function(String) onDataReceived) async {
    try {
      _activeProcess = await Process.start(executable, arguments);
      _currentPid = _activeProcess?.pid;
      print("🚀 Processus offensif démarré avec le PID : $_currentPid");

      _activeProcess?.stdout.transform(const SystemEncoding().decoder).listen((data) {
        onDataReceived(data);
      });

      _activeProcess?.stderr.transform(const SystemEncoding().decoder).listen((data) {
        onDataReceived("ERREUR: $data");
      });

      int exitCode = await _activeProcess!.exitCode;
      print("🏁 Processus terminé avec le code : $exitCode");
    } catch (e) {
      print("❌ Erreur lors de l'exécution du processus : $e");
    }
  }

  /// Arrêt d'urgence (Kill Switch local)[cite: 7]
  void killActiveProcess() {
    if (_activeProcess != null && _currentPid != null) {
      bool success = _activeProcess!.kill(ProcessSignal.sigkill);
      if (success) {
        print("🛑 Arrêt d'urgence réussi pour le processus PID : $_currentPid");
      } else {
        print("⚠️ Impossible d'arrêter le processus PID : $_currentPid");
      }
      _activeProcess = null;
      _currentPid = null;
    } else {
      print("ℹ️ Aucun processus actif à stopper.");
    }
  }
}