import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

// Base de données en mémoire (Append-Only log conseillé en production)
List<Map<String, dynamic>> honeypotAlerts = [];

void main() async {
  final app = Router();

  // 1. Endpoint pour enregistrer une intrusion (appelé par le pot de miel)
  app.post('/api/honeypot/trigger', (Request request) async {
    try {
      final payload = await request.readAsString();
      final data = jsonDecode(payload) as Map<String, dynamic>;

      final alert = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'trigger_type': data['trigger_type'] ?? 'Accès non autorisé',
        'ip_address': data['ip_address'] ?? '0.0.0.0',
        'device_fingerprint': data['device_fingerprint'] ?? 'Inconnu',
        'user_id': data['user_id'] ?? 'anonymous',
        'timestamp': DateTime.now().toIso8601String(),
      };

      honeypotAlerts.insert(0, alert);
      print('[ALERTE HONEYPOT] Intrusion détectée depuis ${alert['ip_address']}');

      return Response.ok(
        jsonEncode({'status': 'success', 'message': 'Alerte enregistrée'}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.badRequest(body: jsonEncode({'error': e.toString()}));
    }
  });

  // 2. Endpoint pour récupérer la liste des alertes (pour l'interface Super Admin)
  app.get('/api/honeypot/alerts', (Request request) {
    return Response.ok(
      jsonEncode(honeypotAlerts),
      headers: {'Content-Type': 'application/json'},
    );
  });

  // 3. Endpoint de "Contenir l'attaque" (Bannissement IP & révocation)
  app.post('/api/honeypot/block', (Request request) async {
    final payload = await request.readAsString();
    final data = jsonDecode(payload) as Map<String, dynamic>;
    final String ip = data['ip_address'] ?? '';

    // Logique de simulation d'interaction pare-feu[cite: 12]
    print('[ACTION SÉCURITÉ] Bannissement de l\'IP : $ip et invalidation des sessions.');

    // Supprimer l'alerte traitée de la liste active
    honeypotAlerts.removeWhere((alert) => alert['ip_address'] == ip);

    return Response.ok(
      jsonEncode({'status': 'success', 'message': 'IP $ip bannie et isolée du réseau.'}),
      headers: {'Content-Type': 'application/json'},
    );
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(app);

  final server = await shelf_io.serve(handler, '0.0.0.0', 8080);
  print('Serveur de sécurité honeypot actif sur http://${server.address.host}:${server.port}');
}