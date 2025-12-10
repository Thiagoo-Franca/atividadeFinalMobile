class AppUser {
  final String id;
  final String name;
  final String email;

  AppUser({required this.id, required this.name, required this.email});

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    id: map['id'] as String,
    name: map['name'] as String,
    email: map['email'] as String,
  );
}
