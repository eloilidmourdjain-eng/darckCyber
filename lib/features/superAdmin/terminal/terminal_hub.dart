import 'dart:io';
import 'package:darck_puls/features/superAdmin/terminal/desktop_terminal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:darck_puls/features/superAdmin/terminal/mobile_terminal.dart';

class TerminalHub extends StatelessWidget {
  const TerminalHub({super.key});

  @override
  Widget build(BuildContext context) {
    // Si l'application tourne sur le Web ou sur une plateforme Desktop
    if (kIsWeb) {
      return const MobileTerminalView();
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Chargement sécurisé du moteur PTY Réel pour PC
      return const DesktopTerminalView();
    } else {
      // Chargement du terminal simulé par dictionnaire pour Android / iOS
      return const MobileTerminalView();
    }
  }
}