class Game {
  final int id;
  final int roundsId;
  final int timeAId;
  final int timeBId;
  final String championshipOwnerId;
  final int championshipId;
  int? golsTimeA;
  int? golsTimeB;

  Game({
    required this.id,
    required this.roundsId,
    required this.timeAId,
    required this.timeBId,
    required this.championshipOwnerId,
    required this.championshipId,
    this.golsTimeA,
    this.golsTimeB,
  });

  factory Game.fromMap(Map<String, dynamic> map) {
    print('Mapping Game from map: $map');
    return Game(
      id: map['id'] is int ? map['id'] : int.parse(map['id'].toString()),
      roundsId: map['rounds_id'] is int
          ? map['rounds_id']
          : int.parse(map['rounds_id'].toString()),
      championshipId: map['championship_id'] as int,

      timeAId: map['time_a_id'] is int
          ? map['time_a_id']
          : int.parse(map['time_a_id'].toString()),
      timeBId: map['time_b_id'] is int
          ? map['time_b_id']
          : int.parse(map['time_b_id'].toString()),
      golsTimeA: map['gols_time_A'] == null
          ? null
          : (map['gols_time_A'] is int
                ? map['gols_time_A']
                : int.parse(map['gols_time_A'].toString())),
      golsTimeB: map['gols_time_B'] == null
          ? null
          : (map['gols_time_B'] is int
                ? map['gols_time_B']
                : int.parse(map['gols_time_B'].toString())),
      championshipOwnerId: map['championshipOwner_id'] as String,
    );
  }
}
