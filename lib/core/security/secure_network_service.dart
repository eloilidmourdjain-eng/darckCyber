import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

class SecureNetworkService {
  static const String _primaryPin = "VOTRE_EMPREINTE_SHA256_BASE64_PRINCIPALE=";
  static const String _backupPin = "VOTRE_EMPREINTE_SHA256_BASE64_SECOURS=";

  static HttpClient createPinnedHttpClient() {
    final client = HttpClient();
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      final digest = sha256.convert(cert.der);
      final actualPin = base64.encode(digest.bytes);
      return actualPin == _primaryPin || actualPin == _backupPin;
    };
    return client;
  }
}
