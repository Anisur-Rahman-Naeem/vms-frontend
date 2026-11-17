/// Model representing the authenticated user in the admin portal.
class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? initials;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.initials,
  });
}

