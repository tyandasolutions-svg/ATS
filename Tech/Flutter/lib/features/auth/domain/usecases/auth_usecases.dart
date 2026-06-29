import 'package:dartz/dartz.dart';
import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/core/usecases/usecase.dart';
import 'package:flutter_pos/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';

class LoginWithPinUseCase implements UseCase<UserEntity, String> {
  final AuthRepository repository;

  const LoginWithPinUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(String pin) {
    return repository.loginWithPin(pin);
  }
}

class LogoutUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;

  const LogoutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.logout();
  }
}

class GetCurrentUserUseCase implements UseCase<UserEntity?, NoParams> {
  final AuthRepository repository;

  const GetCurrentUserUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity?>> call(NoParams params) {
    return repository.getCurrentUser();
  }
}

class GetAllUsersUseCase implements UseCase<List<UserEntity>, NoParams> {
  final AuthRepository repository;

  const GetAllUsersUseCase(this.repository);

  @override
  Future<Either<Failure, List<UserEntity>>> call(NoParams params) {
    return repository.getAllUsers();
  }
}
