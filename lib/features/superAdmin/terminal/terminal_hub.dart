import 'package:flutter/material.dart';

class TerminalHub extends StatelessWidget {
  const TerminalHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "root@darck-pulse-hub:~# tty",
            style: TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            "/dev/pts/1 - Hub terminal sécurisé actif.",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
