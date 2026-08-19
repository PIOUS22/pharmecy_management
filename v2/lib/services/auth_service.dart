import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../database/app_database.dart';

class AuthUser {
  final int id;
  final String username;
  final String name;
  final String role;

  const AuthUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
  });

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  AuthUser? currentUser;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  Future<void> initialize() async {
    final db = await AppDatabase.instance.database;

    final users = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: ['admin'],
      limit: 1,
    );

    if (users.isEmpty) {
      await db.insert(
        'users',
        {
          'username': 'admin',
          'password_hash': _hashPassword('admin123'),
          'name': 'Administrator',
          'role': 'admin',
          'active': 1,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      return;
    }

    final existing = users.first;

    if (existing['password_hash'] == 'CHANGE_ME') {
      await db.update(
        'users',
        {
          'password_hash': _hashPassword('admin123'),
        },
        where: 'id = ?',
        whereArgs: [existing['id']],
      );
    }
  }

  Future<AuthUser?> login(
    String username,
    String password,
  ) async {
    final db = await AppDatabase.instance.database;

    final passwordHash = _hashPassword(password);

    final users = await db.query(
      'users',
      where: '''
        username = ?
        AND password_hash = ?
        AND active = 1
      ''',
      whereArgs: [
        username.trim(),
        passwordHash,
      ],
      limit: 1,
    );

    if (users.isEmpty) {
      return null;
    }

    final user = users.first;

    currentUser = AuthUser(
      id: user['id'] as int,
      username: user['username'] as String,
      name: user['name'] as String,
      role: user['role'] as String,
    );

    return currentUser;
  }

  void logout() {
    currentUser = null;
  }

  Future<List<Map<String, Object?>>> getUsers() async {
    final db = await AppDatabase.instance.database;

    return db.query(
      'users',
      orderBy: 'name COLLATE NOCASE ASC',
    );
  }

  Future<int> createUser({
    required String username,
    required String password,
    required String name,
    required String role,
  }) async {
    if (username.trim().isEmpty) {
      throw Exception('Username is required');
    }

    if (password.length < 6) {
      throw Exception(
        'Password must be at least 6 characters',
      );
    }

    if (role != 'admin' && role != 'staff') {
      throw Exception('Invalid user role');
    }

    final db = await AppDatabase.instance.database;

    return db.insert(
      'users',
      {
        'username': username.trim(),
        'password_hash': _hashPassword(password),
        'name': name.trim(),
        'role': role,
        'active': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> changePassword({
    required int userId,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      throw Exception(
        'Password must be at least 6 characters',
      );
    }

    final db = await AppDatabase.instance.database;

    await db.update(
      'users',
      {
        'password_hash': _hashPassword(newPassword),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> setUserActive({
    required int userId,
    required bool active,
  }) async {
    final db = await AppDatabase.instance.database;

    await db.update(
      'users',
      {
        'active': active ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
