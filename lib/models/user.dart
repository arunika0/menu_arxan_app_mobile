
class User {
  final String username;
  final String role;
  final int? restaurantId;

  User({
    required this.username,
    required this.role,
    this.restaurantId,
  });
}