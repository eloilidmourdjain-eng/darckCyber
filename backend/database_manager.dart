import 'dart:io';
import 'package:sqlite3/sqlite3.dart';
import 'package:path/path.dart' as p;

class DatabaseManager {
  // Singleton pattern : Une seule connexion à la DB pour tout le serveur
  static final DatabaseManager _instance = DatabaseManager._internal();
  factory DatabaseManager() => _instance;

  late Database _db;

  DatabaseManager._internal();

  /// Initialise la base de données et crée les tables si elles n'existent pas
  void init() {
    // Crée le fichier de la base de données dans le dossier du serveur
    final dbPath = p.join(Directory.current.path, 'dark_pulse_core.sqlite');
    _db = sqlite3.open(dbPath);
    print("🗄️ [DB] Base de données connectée : $dbPath");

    _createTables();
  }

  void _createTables() {
    // 1. Table des Logs de Sécurité (SIEM)
    _db.execute('''
      CREATE TABLE IF NOT EXISTS security_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        threat_type TEXT NOT NULL,
        source_ip TEXT NOT NULL,
        severity TEXT NOT NULL,
        severity_score REAL NOT NULL,
        raw_log TEXT
      );
    ''');

    // 2. Table des Utilisateurs (RBAC - Role Based Access Control)
    _db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER DEFAULT 1
      );
    ''');

    // 3. Table des Endpoints (Appareils détectés sur le réseau)
    _db.execute('''
      CREATE TABLE IF NOT EXISTS endpoints (
        mac_address TEXT PRIMARY KEY,
        last_ip TEXT NOT NULL,
        os_type TEXT,
        is_quarantined INTEGER DEFAULT 0,
        last_seen TEXT NOT NULL
      );
    ''');

    print("✅ [DB] Schéma relationnel vérifié et validé.");
  }

  // ==========================================
  // REQUÊTES (C.R.U.D) SÉCURISÉES
  // ==========================================

  /// Enregistre une alerte SIEM dans la base (Prévention des injections SQL via les '?' )
  void insertSecurityLog({
    required String eventId,
    required String timestamp,
    required String threatType,
    required String sourceIp,
    required String severity,
    required double score,
    required String rawLog,
  }) {
    final stmt = _db.prepare('INSERT INTO security_logs (event_id, timestamp, threat_type, source_ip, severity, severity_score, raw_log) VALUES (?, ?, ?, ?, ?, ?, ?)');
    stmt.execute([eventId, timestamp, threatType, sourceIp, severity, score, rawLog]);
    stmt.dispose();
  }

  /// Récupère les 100 derniers logs pour les envoyer à l'application mobile au démarrage
  List<Map<String, dynamic>> getRecentLogs() {
    final ResultSet resultSet = _db.select('SELECT * FROM security_logs ORDER BY id DESC LIMIT 100');

    List<Map<String, dynamic>> logs = [];
    for (final row in resultSet) {
      logs.add({
        "id": row['event_id'],
        "timestamp": row['timestamp'],
        "title": row['threat_type'],
        "source_ip": row['source_ip'],
        "severity": row['severity'],
        "severity_score": row['severity_score'],
        "raw_log": row['raw_log']
      });
    }
    return logs;
  }

  void close() {
    _db.dispose();
  }
}