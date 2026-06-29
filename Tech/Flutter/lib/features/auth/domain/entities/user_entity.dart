import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String pin;
  final String role;
  final bool isActive;
  final String? avatarPath;
  final DateTime? createdAt;

  const UserEntity({
    required this.id,
    required this.name,
    this.email,
    required this.pin,
    required this.role,
    this.isActive = true,
    this.avatarPath,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isCashier => role == 'cashier';

  @override
  List<Object?> get props => [id, name, email, pin, role, isActive];
}
