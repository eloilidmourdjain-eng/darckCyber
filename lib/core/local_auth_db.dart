import 'dart:convert';
import 'package:crypto/crypto.dart';
import "package:sqflite/sqflite.dart";
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'package:darck_puls/core/models/user_role.dart';

class LocalAuthDatabase {
  static final LocalAuthDatabase instance = LocalAuthDatabase._init();
  static Database? _database;

  LocalAuthDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('darkpulse_auth.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // DEVSECOPS : Les mots de passe ne sont JAMAIS stockés en clair
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        is_first_login INTEGER NOT NULL,
        is_active INTEGER NOT NULL
      )
    ''');
  }

  // --- CRYPTOGRAPHIE ---
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // --- ACTIONS (C.R.U.D) ---

  /// Insère le SuperAdmin au tout premier lancement
  Future<void> createRootUser(String name, String email, String password) async {
    final db = await instance.database;
    await db.insert('users', {
      'id': 'USR-ROOT',
      'name': name,
      'email': email,
      'password_hash': _hashPassword(password),
      'role': 'superAdmin',
      'is_first_login': 0, // Le Root n'a pas besoin de faire l'onboarding
      'is_active': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace); // Remplace si existe déjà
  }

  /// Le SuperAdmin ajoute un SimpleAdmin
  Future<void> provisionAdmin(String id, String name, String email, String tempPassword) async {
    final db = await instance.database;
    await db.insert('users', {
      'id': id,
      'name': name,
      'email': email,
      'password_hash': _hashPassword(tempPassword),
      'role': 'simpleAdmin',
      'is_first_login': 1, // 👈 Forcera la page ProfileCompletionScreen
      'is_active': 1,
    });
  }

  /// Authentification
  Future<Map<String, dynamic>?> authenticateUser(String email, String password) async {
    final db = await instance.database;
    final hash = _hashPassword(password);

    final maps = await db.query(
      'users',
      where: 'email = ? AND password_hash = ? AND is_active = 1',
      whereArgs: [email, hash],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null; // Échec
  }

  /// Récupère tous les utilisateurs (pour l'onglet IAM du SuperAdmin)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await instance.database;
    return await db.query('users', orderBy: 'role DESC');
  }
}