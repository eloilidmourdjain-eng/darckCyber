import 'package:http/io_client.dart';
import 'package:darck_puls/core/security/secure_network_service.dart';

Future<void> fetchData() async {
  final secureHttpClient = SecureNetworkService.createPinnedHttpClient();
  final ioClient = IOClient(secureHttpClient);

  try {
    final response = await ioClient.get(Uri.parse('https://api.internal-soc.com/data'));
    print(response.body);
  } catch (e) {
    print("Erreur de connexion sécurisée : $e");
  } finally {
    ioClient.close();
  }
}