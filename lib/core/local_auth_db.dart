import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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

    // 🚀 DEVSECOPS : INJECTION DU SUPER ADMIN PAR DÉFAUT
    // Identifiants par défaut : Email: root@darkpulse.local | MDP: admin123
    var bytes = utf8.encode("admin123");
    var defaultHash = sha256.convert(bytes).toString();

    await db.insert('users', {
      'id': 'USR-ROOT-DEFAULT',
      'name': 'Super Admin (Default)',
      'email': 'root@darkpulse.local', // 👈 L'email pour se connecter
      'password_hash': defaultHash,    // 👈 Le mot de passe haché de "admin123"
      'role': 'superAdmin',
      'is_first_login': 1,             // 👈 1 = FORCE LE CHANGEMENT DE PROFIL AU PREMIER LOGIN
      'is_active': 1,
    });
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<void> provisionAdmin(String id, String name, String email, String tempPassword) async {
    final db = await instance.database;
    await db.insert('users', {
      'id': id, 'name': name, 'email': email, 'password_hash': _hashPassword(tempPassword),
      'role': 'simpleAdmin', 'is_first_login': 1, 'is_active': 1,
    });
  }

  Future<Map<String, dynamic>?> authenticateUser(String email, String password) async {
    final db = await instance.database;
    final hash = _hashPassword(password);
    final maps = await db.query('users', where: 'email = ? AND password_hash = ? AND is_active = 1', whereArgs: [email, hash]);
    if (maps.isNotEmpty) return maps.first;
    return null;
  }

  // 🚀 NOUVEAU : MET À JOUR LE PROFIL ET DÉSACTIVE LE "FIRST LOGIN"
  Future<void> completeUserProfile(String email, String newPassword) async {
    final db = await instance.database;
    final newHash = _hashPassword(newPassword);

    await db.update(
        'users',
        {
          'password_hash': newHash,
          'is_first_login': 0 // Le profil est complété, l'utilisateur est libéré
        },
        where: 'email = ?',
        whereArgs: [email]
    );
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await instance.database;
    return await db.query('users', orderBy: 'role DESC');
  }
}