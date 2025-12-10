import 'package:flutter/material.dart';
import 'package:myapp/models/game.dart';
import 'package:myapp/models/team.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> loadTeams() async {
    try {
      print('Loading teams...');

      final results = await Supabase.instance.client
          .from('teams')
          .select()
          .order('name');

      _teams = (results as List).map((e) => Team.fromMap(e)).toList();
      print('Teams loaded: ${_teams.length}');

      if (_teams.isEmpty) {
        print('⚠️ WARNING: No teams found in database');
      } else {
        print('Teams: ${_teams.map((t) => t.name).join(", ")}');
      }

      notifyListeners();
    } catch (e) {
      _error = 'Erro ao buscar times: $e';
      print('Error loading teams: $e');
      notifyListeners();
    }
  }

  Future<void> loadGamesForCurrentRound(
    int championshipId,
    int roundNumber,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Supabase.instance.client
          .from('games')
          .select()
          .eq('championship_id', championshipId)
          .eq('rounds_id', roundNumber);

      _games = (results as List).map((e) => Game.fromMap(e)).toList();
      if (_games.isEmpty) {
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

  Future<void> createGame({
    required int championshipId,
    required int roundsId,
    required int timeAId,
    required int timeBId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final championship = await Supabase.instance.client
          .from('championship')
          .select('owner_id')
          .eq('id', championshipId)
          .single();

      final ownerId = championship['owner_id'] as String;
      final championshipOwnerId = ownerId;

      print(
        'Creating game: Championship $championshipId, Round $roundsId, $timeAId vs $timeBId',
      );

      final response = await Supabase.instance.client
          .from('games')
          .insert({
            'championship_id': championshipId,
            'championshipOwner_id': championshipOwnerId,
            'rounds_id': roundsId,
            'time_a_id': timeAId,
            'time_b_id': timeBId,
            'gols_time_A': null,
            'gols_time_B': null,
          })
          .select()
          .single();

      final newGame = Game.fromMap(response);
      _games.add(newGame);

      print('Game created successfully: ${newGame.id}');
      _error = null;
    } catch (e) {
      _error = 'Erro ao criar jogo: $e';
      print('Error creating game: $e');
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
