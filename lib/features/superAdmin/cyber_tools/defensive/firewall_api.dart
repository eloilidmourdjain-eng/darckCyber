import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';

class OperationalCyberManager {
  // ==========================================
  // CONFIGURATION DEVSECOPS (Clés SSH)
  // ==========================================
  static const String _user = 'root';

  // Mettre à jour avec l'IP de ton vrai routeur/serveur cible
  static const String _defaultRouterIp = '192.168.1.1';

  /// Ouvre une connexion SSH utilisant une Clé Privée (Ed25519 ou RSA)
  static Future<SSHClient> _createSecureSession(String targetHost) async {
    // ⚠️ EN PRODUCTION : Stocker cette clé dans le Flutter Secure Storage
    // Ici, nous simulons la lecture d'une clé RSA/PEM
    const String privateKey = '''
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
... (REMPLACE CECI PAR TA VRAIE CLÉ PRIVÉE SI TU VEUX TESTER EN VRAI) ...
-----END OPENSSH PRIVATE KEY-----''';

    final socket = await SSHSocket.connect(targetHost, 22, timeout: const Duration(seconds: 5));

    return SSHClient(
      socket,
      username: _user,
      identities: [
        ...SSHKeyPair.fromPem(privateKey)
      ],
      // Fallback sur mot de passe si la clé échoue (Optionnel)
      onPasswordRequest: () => String.fromEnvironment('SSH_PASSWORD', defaultValue: ''),
    );
  }

  /// 🛡️ ACTION SOAR : Bannissement réel via Iptables / UFW
  static Future<bool> banIpAddress(String attackerIp, {String targetHost = _defaultRouterIp}) async {
    // 1. Validation Anti-Injection (Critique)
    final ipRegex = RegExp(r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$');
    if (!ipRegex.hasMatch(attackerIp)) {
      debugPrint("❌ [SEC-ALERT] Rejet: Tentative d'injection shell avec l'IP: $attackerIp");
      return false;
    }

    try {
      debugPrint("🛡️ [SOAR] Établissement du tunnel SSH vers $targetHost...");
      final client = await _createSecureSession(targetHost);

      // 2. Exécution de la commande de bannissement
      // On utilise 'iptables' qui est universel sur Linux (plus que UFW)
      final command = 'iptables -I INPUT -s $attackerIp -j DROP';
      debugPrint("⚡ [SOAR] Exécution : $command");

      final session = await client.execute(command);
      final stderr = utf8.decode(await session.stderr.first);

      client.close();

      // Si stderr est vide, la commande iptables a réussi
      if (stderr.trim().isEmpty) {
        debugPrint("✅ [SOAR] L'IP $attackerIp a été neutralisée avec succès.");
        return true;
      } else {
        debugPrint("⚠️ [SOAR] Erreur routeur : $stderr");
        return false;
      }
    } catch (e) {
      debugPrint("❌ [CRITICAL] Échec de la connexion SSH : $e");
      return false;
    }
  }
}