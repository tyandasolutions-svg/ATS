import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final int loyaltyPoints;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomerEntity({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.loyaltyPoints = 0,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, phone, email];
}
