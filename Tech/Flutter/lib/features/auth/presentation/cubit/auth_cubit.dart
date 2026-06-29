import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_pos/core/usecases/usecase.dart';
import 'package:flutter_pos/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_pos/features/auth/domain/usecases/auth_usecases.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginWithPinUseCase _loginWithPin;
  final LogoutUseCase _logout;
  final GetCurrentUserUseCase _getCurrentUser;

  AuthCubit({
    required LoginWithPinUseCase loginWithPin,
    required LogoutUseCase logout,
    required GetCurrentUserUseCase getCurrentUser,
  })  : _loginWithPin = loginWithPin,
        _logout = logout,
        _getCurrentUser = getCurrentUser,
        super(const AuthInitial());

  Future<void> checkAuthStatus() async {
    final result = await _getCurrentUser(const NoParams());
    result.fold(
      (failure) => emit(const AuthUnauthenticated()),
      (user) {
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  Future<void> loginWithPin(String pin) async {
    emit(const AuthLoading());

    final result = await _loginWithPin(pin);
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthAuthenticated(user: user)),
    );
  }

  Future<void> logout() async {
    emit(const AuthLoading());

    final result = await _logout(const NoParams());
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }
}
