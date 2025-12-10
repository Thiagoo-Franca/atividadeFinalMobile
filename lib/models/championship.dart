class Championship {
  final int id;
  final String name;

  Championship({required this.id, required this.name});

  factory Championship.fromMap(Map<String, dynamic> map) =>
      Championship(id: map['id'] as int, name: map['name'] as String);
}
