import 'package:flutter_pos/core/database/app_database.dart';
import 'package:flutter_pos/core/errors/exceptions.dart';
import 'package:flutter_pos/features/auth/data/models/user_model.dart';
import 'package:drift/drift.dart';

abstract class AuthLocalDataSource {
  Future<UserModel> loginWithPin(String pin);
  Future<List<UserModel>> getAllUsers();
  Future<UserModel> createUser(UserModel user);
  Future<UserModel> updateUser(UserModel user);
  Future<void> deleteUser(String userId);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final AppDatabase _db;

  const AuthLocalDataSourceImpl(this._db);

  @override
  Future<UserModel> loginWithPin(String pin) async {
    try {
      final query = _db.select(_db.users)
        ..where((u) => u.pin.equals(pin))
        ..where((u) => u.isActive.equals(true));

      final result = await query.getSingleOrNull();
      if (result == null) {
        throw const AuthException(message: 'PIN tidak valid');
      }

      return UserModel(
        id: result.id,
        name: result.name,
        email: result.email,
        pin: result.pin,
        role: result.role,
        isActive: result.isActive,
        avatarPath: result.avatarPath,
        createdAt: result.createdAt,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    try {
      final results = await _db.select(_db.users).get();
      return results
          .map((u) => UserModel(
                id: u.id,
                name: u.name,
                email: u.email,
                pin: u.pin,
                role: u.role,
                isActive: u.isActive,
                avatarPath: u.avatarPath,
                createdAt: u.createdAt,
              ))
          .toList();
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }

  @override
  Future<UserModel> createUser(UserModel user) async {
    try {
      await _db.into(_db.users).insert(UsersCompanion.insert(
            id: user.id,
            name: user.name,
            email: Value(user.email),
            pin: user.pin,
            role: Value(user.role),
            isActive: Value(user.isActive),
            avatarPath: Value(user.avatarPath),
            createdAt: Value(DateTime.now()),
          ));
      return user;
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }

  @override
  Future<UserModel> updateUser(UserModel user) async {
    try {
      await (_db.update(_db.users)..where((u) => u.id.equals(user.id))).write(
        UsersCompanion(
          name: Value(user.name),
          email: Value(user.email),
          pin: Value(user.pin),
          role: Value(user.role),
          isActive: Value(user.isActive),
          avatarPath: Value(user.avatarPath),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return user;
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await (_db.delete(_db.users)..where((u) => u.id.equals(userId))).go();
    } catch (e) {
      throw DatabaseException(message: e.toString());
    }
  }
}
