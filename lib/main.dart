import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

class RoundProvider extends ChangeNotifier {
  int _currentRound = 1;
  final int _totalRounds = 6;

  int get currentRound {
    print('Getting current round: $_currentRound');
    return _currentRound;
  }

  int get totalRounds {
    print('Getting total rounds: $_totalRounds');
    return _totalRounds;
  }

  void nextRound() {
    if (_currentRound < _totalRounds) {
      _currentRound++;
      notifyListeners();
    }
  }

  void previousRound() {
    if (_currentRound > 1) {
      _currentRound--;
      notifyListeners();
    }
  }
}

class GameProvider extends ChangeNotifier {
  List<Game> _games = [];
  List<Team> _teams = [];
  bool _isLoading = false;
  String? _error;

  List<Game> get games => _games;
  List<Team> get teams => _teams;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String getTeamName(int teamId) {
    try {
      return _teams.firstWhere((team) => team.id == teamId).name;
    } catch (e) {
      return 'Time $teamId';
    }
  }

  Future<void> loadGames() async {
    try {
      final results = await Supabase.instance.client.from('teams').select();
      _teams = (results as List).map((e) => Team.fromMap(e)).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao buscar dados: $e';
      notifyListeners();
    }
  }

  Future<void> loadGamesForCurrentRound(int roundNumber) async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Supabase.instance.client
          .from('games')
          .select()
          .eq('rounds_id', roundNumber);

      _games = (results as List).map((e) => Game.fromMap(e)).toList();
      if (_games.length == 0) {
        print('No games found for round $roundNumber');
      } else {
        print('Games found for round $roundNumber: ${_games.length}');
      }
      print('Games loaded for round $roundNumber: ${_games.length}');
      _error = null;
    } catch (e) {
      _error = 'Erro ao buscar dados: $e';
      print('Error loading games for round $roundNumber: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateGameResultLocally(int gameId, int golsTimeA, int golsTimeB) {
    try {
      final gameIndex = _games.indexWhere((game) => game.id == gameId);
      if (gameIndex != -1) {
        _games[gameIndex].golsTimeA = golsTimeA;
        _games[gameIndex].golsTimeB = golsTimeB;
        notifyListeners();
      } else {
        print('Game with id $gameId not found.');
      }
    } catch (e) {
      print('Error updating game result locally: $e');
    }
  }

  Future<void> saveAllGames() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      for (var game in _games) {
        await Supabase.instance.client
            .from('games')
            .update({
              'gols_time_A': game.golsTimeA,
              'gols_time_B': game.golsTimeB,
            })
            .eq('id', game.id);
      }
      print('Todos jogos salvos com sucesso!');
    } catch (e) {
      _error = 'Erro ao salvar jogos: $e';
      print('Erro ao salvar jogos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class Team {
  final int id;
  final String name;

  Team({required this.id, required this.name});

  factory Team.fromMap(Map<String, dynamic> map) =>
      Team(id: map['id'] as int, name: map['name'] as String);
}

class Round {
  final int id;
  final int number;

  Round({required this.id, required this.number});

  factory Round.fromMap(Map<String, dynamic> map) =>
      Round(id: map['id'] as int, number: map['number'] as int);
}

class Game {
  final int id;
  final int roundsId;
  final int timeAId;
  final int timeBId;
  int? golsTimeA;
  int? golsTimeB;

  Game({
    required this.id,
    required this.roundsId,
    required this.timeAId,
    required this.timeBId,
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
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://douwctlommhpagyfdanb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvdXdjdGxvbW1ocGFneWZkYW5iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwOTA0NzAsImV4cCI6MjA3OTY2NjQ3MH0.MOQddEYhLsaNgGc7tkdokMlQqL9olI0hV-qJsnBBwCs',
  );
  /*
  await Supabase.instance.client.from('Equipe').insert([
    {'id': 1, 'name': 'Time A'},
    {'id': 2, 'name': 'Time B'},
    {'id': 3, 'name': 'Time C'},
    {'id': 4, 'name': 'Time D'},
  ]);
  await Supabase.instance.client.from('matches').insert([
    {'id': 1, 'number': 1},
    {'id': 2, 'number': 2},
    {'id': 3, 'number': 3},
  ]);
  await Supabase.instance.client.from('match').insert([
    {'id': 1, 'matches_id': 1, 'time_a_id': 1, 'time_b_id': 2},

    {'id': 2, 'matches_id': 1, 'time_a_id': 3, 'time_b_id': 4},
    {'id': 3, 'matches_id': 2, 'time_a_id': 1, 'time_b_id': 3},
    {'id': 4, 'matches_id': 2, 'time_a_id': 2, 'time_b_id': 4},
  ]);
*/

  try {
    final results = await Supabase.instance.client.from('teams').select();

    final teams = (results as List).map((e) => Team.fromMap(e)).toList();

    print('Times:  ${teams.length}');
    for (var team in teams) {
      print('Time: id=${team.id}, name=${team.name}');
    }
  } catch (e) {
    print('Erro ao buscar dados: $e');
  }

  try {
    final results = await Supabase.instance.client.from('rounds').select();

    final rounds = (results as List).map((e) => Round.fromMap(e)).toList();
    print('Dados da tabela rounds: ${rounds.length}');
    for (var round in rounds) {
      print('Round: id=${round.id}, number=${round.number}');
    }
  } catch (e) {
    print('Erro ao buscar dados: $e');
  }

  try {
    final results = await Supabase.instance.client.from('games').select();

    final games = (results as List).map((e) => Game.fromMap(e)).toList();
    print('Dados da tabela games: ${games.length}');
    for (var game in games) {
      print(
        'Game: id=${game.id}, rounds_id=${game.roundsId}, time_a_id=${game.timeAId}, time_b_id=${game.timeBId}, gols_time_A=${game.golsTimeA}, gols_time_B=${game.golsTimeB}',
      );
    }
  } catch (e) {
    print('Erro ao buscar dados: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RoundProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = context.read<GameProvider>();
      final roundProvider = context.read<RoundProvider>();

      gameProvider.loadGames();
      gameProvider.loadGamesForCurrentRound(roundProvider.currentRound);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: Consumer2<RoundProvider, GameProvider>(
        builder: (context, roundProvider, gameProvider, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                "eFootRounds",
                style: TextStyle(
                  color: const Color.fromARGB(255, 255, 249, 230),
                  fontSize: 32,
                ),
              ),
              backgroundColor: Colors.red[400],
              centerTitle: true,
            ),
            body: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        roundProvider.previousRound();
                        gameProvider.loadGamesForCurrentRound(
                          roundProvider.currentRound,
                        );
                      },
                      child: Center(
                        child: Icon(Icons.arrow_back_ios_new_outlined),
                      ),
                    ),
                    Text(
                      "Rodada ${roundProvider.currentRound}",
                      style: TextStyle(fontSize: 18),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        roundProvider.nextRound();
                        gameProvider.loadGamesForCurrentRound(
                          roundProvider.currentRound,
                        );
                      },
                      child: Center(
                        child: Icon(Icons.arrow_forward_ios_outlined),
                      ),
                    ),
                  ],
                ),
                if (gameProvider.isLoading)
                  CircularProgressIndicator()
                else if (gameProvider.games.length == 0)
                  Text("Nenhum jogo encontrado para esta rodada.")
                else
                  ...gameProvider.games.map(
                    (game) => Clash(
                      game: game,
                      teamAName: gameProvider.getTeamName(game.timeAId),
                      teamBName: gameProvider.getTeamName(game.timeBId),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      child: Center(
                        child: Icon(
                          Icons.close_outlined,
                          color: Colors.red[600],
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final gameProvider = context.read<GameProvider>();
                        await gameProvider.saveAllGames();

                        if (gameProvider.error == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Jogos salvos com sucesso!'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Erro ao salvar jogos: ${gameProvider.error}',
                              ),
                            ),
                          );
                        }
                      },
                      label: Text("Salvar"),
                      icon: Icon(Icons.check_rounded, color: Colors.green[400]),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class Clash extends StatelessWidget {
  final Game game;
  final String teamAName;
  final String teamBName;

  const Clash({
    super.key,
    required this.game,
    required this.teamAName,
    required this.teamBName,
  });

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.read<GameProvider>();

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              teamAName,
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
            SizedBox(
              height: 32,
              width: 32,
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                controller: TextEditingController(
                  text: game.golsTimeA?.toString() ?? '',
                ),
                onChanged: (value) {
                  final gols = int.tryParse(value);
                  gameProvider.updateGameResultLocally(
                    game.id,
                    gols ?? 0,
                    game.golsTimeB ?? 0,
                  );
                },
              ),
            ),
            Text("X", style: TextStyle(color: Colors.black, fontSize: 16)),
            SizedBox(
              height: 32,
              width: 32,
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                controller: TextEditingController(
                  text: game.golsTimeB?.toString() ?? '',
                ),
                onChanged: (value) {
                  final gols = int.tryParse(value);
                  gameProvider.updateGameResultLocally(
                    game.id,
                    game.golsTimeA ?? 0,
                    gols ?? 0,
                  );
                },
              ),
            ),
            Text(
              teamBName,
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
