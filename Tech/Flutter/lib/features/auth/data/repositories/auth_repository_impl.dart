import 'package:dartz/dartz.dart';
import 'package:flutter_pos/core/errors/exceptions.dart';
import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:flutter_pos/features/auth/data/models/user_model.dart';
import 'package:flutter_pos/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  UserEntity? _currentUser;

  AuthRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, UserEntity>> loginWithPin(String pin) async {
    try {
      final user = await localDataSource.loginWithPin(pin);
      _currentUser = user;
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithEmail(
    String email,
    String password,
  ) async {
    // TODO: Implement when API is available
    return const Left(AuthFailure(message: 'Belum tersedia'));
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      _currentUser = null;
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    return Right(_currentUser);
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getAllUsers() async {
    try {
      final users = await localDataSource.getAllUsers();
      return Right(users);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> createUser(UserEntity user) async {
    try {
      final result =
          await localDataSource.createUser(UserModel.fromEntity(user));
      return Right(result);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateUser(UserEntity user) async {
    try {
      final result =
          await localDataSource.updateUser(UserModel.fromEntity(user));
      return Right(result);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String userId) async {
    try {
      await localDataSource.deleteUser(userId);
      return const Right(null);
    } on DatabaseException catch (e) {
      return Left(DatabaseFailure(message: e.message));
    }
  }
}
