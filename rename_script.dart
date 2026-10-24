import 'dart:io';

void main() {
  final dir = Directory('lib');

  if (!dir.existsSync()) {
    print("❌ Dossier 'lib' introuvable. Placez-vous à la racine du projet.");
    return;
  }

  print("🚀 Démarrage du script de Renommage de la Marque (Branding)...");
  int modifiedFiles = 0;
  int replacements = 0;

  for (var file in dir.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;

    String content = file.readAsStringSync();
    bool isModified = false;

    // --- DICTIONNAIRE DES REMPLACEMENTS ULTRA-PRÉCIS ---
    // Cible toutes les variantes avec le "e" final pour les remplacer par "Puls" sans "e"
    final map = {
      'Darck pulse': 'Darck Puls',
      'Darck Pulse': 'Darck Puls',
      'Dark pulse': 'Darck Puls',
      'Dark Pulse': 'Darck Puls',

      // Variantes en majuscules (Pour les titres)
      'DARCK PULSE': 'DARCK PULS',
      'DARK PULSE': 'DARCK PULS',

      // Anciens noms (Optionnel, au cas où)
      'DarckCyber': 'Darck Puls',
      'DARCK_CYBER': 'DARCK_PULS',
    };

    map.forEach((oldText, newText) {
      if (content.contains(oldText)) {
        replacements += oldText.allMatches(content).length;
        content = content.replaceAll(oldText, newText);
        isModified = true;
      }
    });

    if (isModified) {
      file.writeAsStringSync(content);
      modifiedFiles++;
      print("✔️ Marque corrigée (sans 'e') dans : ${file.path.split(Platform.pathSeparator).last}");
    }
  }

  print("\n=====================================================");
  print("🎉 RE-BRANDING TERMINÉ AVEC SUCCÈS !");
  print("📂 Fichiers modifiés : $modifiedFiles");
  print("✍️ Textes corrigés : $replacements");
  print("=====================================================\n");
}