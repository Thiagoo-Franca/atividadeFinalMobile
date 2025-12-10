class Team {
  final int id;
  final String name;

  Team({required this.id, required this.name});

  factory Team.fromMap(Map<String, dynamic> map) =>
      Team(id: map['id'] as int, name: map['name'] as String);
}
