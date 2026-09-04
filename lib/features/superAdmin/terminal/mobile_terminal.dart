import 'package:flutter/material.dart';

class MobileTerminalView extends StatelessWidget {
  const MobileTerminalView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "root@darck-puls-mobile:~#",
            style: TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            "Terminal simulé opérationnel sur mobile.",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
