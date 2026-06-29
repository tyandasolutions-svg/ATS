import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String? parentId;
  final String? iconName;
  final int sortOrder;
  final DateTime? createdAt;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.parentId,
    this.iconName,
    this.sortOrder = 0,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, parentId];
}
