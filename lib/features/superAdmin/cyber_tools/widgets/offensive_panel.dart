import 'package:flutter/material.dart';
import 'package:darckcyber/features/superAdmin/cyber_tools/offensive/cli_wrapper.dart';
import 'package:darckcyber/features/superAdmin/cyber_tools/offensive/process_manager.dart';

class OffensiveActionPage extends StatelessWidget {
  const OffensiveActionPage({super.key});

  void _runNmapScan() async {
    final cmData = OffensiveCliWrapper.buildCommand(
      toolName: 'nmap',
      target: '192.168.1.1',
      options: '-A',
    );

    final processManager = OffensiveProcessManager();

    // CORRECTION : On passe exactement les 3 arguments attendus par startTool
    await processManager.startTool(
      cmData['executable'], // 1. L'exécutable (ex: 'nmap')
      cmData['arguments'],   // 2. La liste des arguments ([...])
          (output) => print(output), // 3. Le callback pour recevoir les logs en temps réel
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pentesting - Outils Offensifs')),
      body: Center(
        child: ElevatedButton(
          onPressed: _runNmapScan,
          child: const Text('Lancer le Scan Nmap'),
        ),
      ),
    );
  }
}