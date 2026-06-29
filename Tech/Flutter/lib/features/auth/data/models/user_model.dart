import 'package:flutter_pos/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    super.email,
    required super.pin,
    required super.role,
    super.isActive,
    super.avatarPath,
    super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      pin: json['pin'] as String,
      role: json['role'] as String? ?? 'cashier',
      isActive: json['is_active'] as bool? ?? true,
      avatarPath: json['avatar_path'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'pin': pin,
      'role': role,
      'is_active': isActive,
      'avatar_path': avatarPath,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      pin: entity.pin,
      role: entity.role,
      isActive: entity.isActive,
      avatarPath: entity.avatarPath,
      createdAt: entity.createdAt,
    );
  }
}
