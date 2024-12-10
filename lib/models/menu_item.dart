// lib/models/menu_item.dart
class MenuItem {
  final int id;
  String name;
  double price;
  String description;
  String? imageUrl; // Make imageUrl nullable
  int categoryId;
  String? categoryName;
  String? restaurantName;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    this.imageUrl,  // Update constructor to accept nullable imageUrl
    required this.categoryId,
    this.categoryName,
    this.restaurantName,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    print('Parsing JSON: $json'); // Debug print
    return MenuItem(
      id: int.parse(json['id'].toString()),
      name: json['name'],
      price: double.parse(json['price'].toString()),
      description: json['description'],
      imageUrl: json['image'] ?? json['imageUrl'], // Remove default empty string
      categoryId: int.parse(json['category_id'].toString()),
      categoryName: json['category_name'],
      restaurantName: json['restaurant_name'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'image': imageUrl,  // Allow null value for 'image'
      'category_id': categoryId,
    };
  }
}
