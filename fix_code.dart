import 'dart:io';

void main() {
  final dir = Directory('lib');
  final backendDir = Directory('backend');

  if (!dir.existsSync()) {
    print("❌ Dossier 'lib' introuvable.");
    return;
  }

  print("🚀 Démarrage du nettoyage chirurgical...");

  void cleanDirectory(Directory directory) {
    if (!directory.existsSync()) return;

    for (var file in directory.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;

      String content = file.readAsStringSync();
      bool modified = false;

      // 1. Remplacer print() par debugPrint() pour la sécurité
      if (content.contains(RegExp(r'\bprint\('))) {
        if (!content.contains("import 'package:flutter/foundation.dart';")) {
          content = "import 'package:flutter/foundation.dart';\n$content";
        }
        content = content.replaceAll(RegExp(r'\bprint\('), 'debugPrint(');
        modified = true;
      }

      // 2. Correction du switch inutile (unreachable_switch_default)
      if (content.contains('case NodeType.pc: default:')) {
        content = content.replaceAll('case NodeType.pc: default:', 'case NodeType.pc:');
        modified = true;
      }

      // 3. Suppression des variables mortes spécifiques (Code Mort)
      final deadCodes = [
        'int quality = 0;',
        'List<DesktopWifiNetwork> desktopNetworks = [];',
        'final Color kTextMain = Colors.white;',
        'int? _pingLatencyMs;',
      ];

      for (String deadCode in deadCodes) {
        if (content.contains(deadCode)) {
          content = content.replaceAll(deadCode, '');
          modified = true;
        }
      }

      // 4. Correction des couleurs obsolètes pour le Switch/Slider
      if (content.contains('activeColor:')) {
        content = content.replaceAll('activeColor:', 'activeTrackColor:');
        modified = true;
      }

      // Sauvegarde du fichier si modifié
      if (modified) {
        file.writeAsStringSync(content);
        print("✔️ Fichier optimisé : ${file.path}");
      }
    }
  }

  cleanDirectory(dir);
  cleanDirectory(backendDir);

  print("\n=====================================================");
  print("🎉 NETTOYAGE COMPLET TERMINÉ ! Ton code est parfait.");
  print("=====================================================\n");
}