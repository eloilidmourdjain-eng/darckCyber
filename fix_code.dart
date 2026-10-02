import 'dart:io';

void main() {
  // Le dossier qui contient tout ton code source
  final dir = Directory('lib');

  if (!dir.existsSync()) {
    print("❌ Erreur : Le dossier 'lib' n'existe pas. Placez-vous à la racine du projet.");
    return;
  }

  int fileCount = 0;
  int opacityCount = 0;
  int fontCount = 0;

  print("🚀 Démarrage du script de nettoyage DevSecOps...\n");

  // Parcours récursif de tous les fichiers du projet
  for (var entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      String content = entity.readAsStringSync();
      bool modified = false;

      // 1. Correction globale de withOpacity -> withValues(alpha: )
      if (content.contains('.withOpacity(')) {
        opacityCount += '#'.allMatches(content.replaceAll('.withOpacity(', '#')).length;
        content = content.replaceAll('.withOpacity(', '.withValues(alpha: ');
        modified = true;
      }

      // 2. Correction de la typographie jetbrainsMono -> jetBrainsMono
      if (content.contains('GoogleFonts.jetbrainsMono')) {
        fontCount += '#'.allMatches(content.replaceAll('GoogleFonts.jetbrainsMono', '#')).length;
        content = content.replaceAll('GoogleFonts.jetbrainsMono', 'GoogleFonts.jetBrainsMono');
        modified = true;
      }

      // 3. Correction de l'icône serveur inexistante chez Apple
      if (content.contains('CupertinoIcons.server_rack')) {
        content = content.replaceAll('CupertinoIcons.server_rack', 'Icons.dns');
        modified = true;
      }

      // 4. Correction de activeColor obsolète pour les Switchs
      if (content.contains('activeColor:')) {
        content = content.replaceAll('activeColor:', 'activeTrackColor:');
        modified = true;
      }

      // 5. Sauvegarde si le fichier a été touché
      if (modified) {
        entity.writeAsStringSync(content);
        print("✔️ Mis à jour : ${entity.path}");
        fileCount++;
      }
    }
  }

  print("\n=====================================================");
  print("🎉 NETTOYAGE TERMINÉ AVEC SUCCÈS !");
  print("📂 Fichiers modifiés : $fileCount");
  print("💧 Remplacements 'withOpacity' : $opacityCount");
  print("✍️ Remplacements 'GoogleFonts' : $fontCount");
  print("=====================================================\n");
}