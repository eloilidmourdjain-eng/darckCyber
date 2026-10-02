import 'dart:io';

void main() {
  final dir = Directory('lib');
  final backendDir = Directory('backend'); // Si tu as un dossier backend

  int printCount = 0;
  int switchCount = 0;

  print("🚀 Démarrage du script de nettoyage final...");

  void processDirectory(Directory directory) {
    if (!directory.existsSync()) return;

    for (var entity in directory.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        String content = entity.readAsStringSync();
        bool modified = false;

        // 1. Remplacer print() par debugPrint() (Norme de production)
        // On s'assure d'abord que le fichier importe foundation.dart
        if (content.contains('print(') && !content.contains("import 'package:flutter/foundation.dart';")) {
          content = "import 'package:flutter/foundation.dart';\n" + content;
        }
        if (content.contains('print(')) {
          printCount += '#'.allMatches(content.replaceAll('print(', '#')).length;
          content = content.replaceAll('print(', 'debugPrint(');
          modified = true;
        }

        // 2. Correction du switch (unreachable_switch_default)
        if (content.contains('case NodeType.pc: default: icon =')) {
          content = content.replaceAll('case NodeType.pc: default: icon =', 'case NodeType.pc: icon =');
          switchCount++;
          modified = true;
        }

        // Sauvegarde
        if (modified) {
          entity.writeAsStringSync(content);
          print("✔️ Nettoyé : ${entity.path}");
        }
      }
    }
  }

  processDirectory(dir);
  processDirectory(backendDir);

  print("\n=====================================================");
  print("🎉 NETTOYAGE EXPERT TERMINÉ !");
  print("🤫 'print' sécurisés en 'debugPrint' : $printCount");
  print("🧹 'default' inutiles supprimés : $switchCount");
  print("=====================================================\n");
}