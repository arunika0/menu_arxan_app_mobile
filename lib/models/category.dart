// lib/models/category.dart
class Category {
  final int id;
  final String name;
  final int? restaurantId;

  Category({
    required this.id,
    required this.name,
    this.restaurantId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      restaurantId: json['restaurant_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'restaurant_id': restaurantId,
    };
  }
}
