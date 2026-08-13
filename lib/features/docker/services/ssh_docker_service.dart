import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import '../models/container_model.dart';

class SshDockerService {
  SSHClient? _client;

  /// Établit la connexion SSH sécurisée avec le serveur distant
  Future<bool> connect({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    try {
      final socket = await SSHSocket.connect(host, port);
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );

      // Test rapide de la connexion
      await _client!.run('echo "SSH Connection Test OK"');
      return true;
    } catch (e) {
      _client = null;
      return false;
    }
  }

  /// Déconnecte proprement le client SSH
  void disconnect() {
    _client?.close();
    _client = null;
  }

  /// Vérifie si le client est actuellement connecté
  bool get isConnected => _client != null;

  /// Récupère la liste des conteneurs Docker distants au format JSON
  Future<List<ContainerModel>> getContainers() async {
    if (_client == null) throw Exception("Client SSH non connecté.");

    try {
      // Commande Docker formatée en JSON ligne par ligne
      final result = await _client!.run('docker ps -a --format "{{json .}}"');
      final output = utf8.decode(result);

      if (output.trim().isEmpty) return [];

      final lines = output.split('\n');
      List<ContainerModel> containers = [];

      for (var line in lines) {
        if (line.trim().isNotEmpty) {
          final Map<String, dynamic> jsonData = jsonDecode(line);
          containers.add(ContainerModel.fromJson(jsonData));
        }
      }

      return containers;
    } catch (e) {
      throw Exception("Erreur lors de la récupération des conteneurs : $e");
    }
  }

  /// Démarre un conteneur Docker par son ID ou son nom
  Future<void> startContainer(String containerId) async {
    if (_client == null) throw Exception("Client SSH non connecté.");
    await _client!.run('docker start $containerId');
  }

  /// Arrête un conteneur Docker par son ID ou son nom
  Future<void> stopContainer(String containerId) async {
    if (_client == null) throw Exception("Client SSH non connecté.");
    await _client!.run('docker stop $containerId');
  }

  /// Écoute en continu les statistiques d'utilisation (CPU/RAM) des conteneurs
  Stream<String> streamContainerStats() async* {
    if (_client == null) throw Exception("Client SSH non connecté.");

    try {
      // Exécute la commande de stats en flux continu
      final session = await _client!.execute('docker stats --format "{{json .}}"');

      await for (final data in session.stdout) {
        yield utf8.decode(data);
      }
    } catch (e) {
      yield "Erreur de flux de statistiques : $e";
    }
  }
}