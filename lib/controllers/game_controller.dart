import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/team.dart';
import '../repositories/game_repository.dart';

class GameController extends ChangeNotifier {
  final GameRepository _repository;

  List<Game> _games = [];
  List<Team> _teams = [];
  bool _isLoading = false;
  String? _error;

  GameController(this._repository);

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
      _error = null;

      _teams = await _repository.getAllTeams();

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadTeamsByChampionship(int championshipId) async {
    try {
      print('Loading teams for championship $championshipId...');
      _error = null;

      _teams = await _repository.getTeamsByChampionship(championshipId);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> createTeam({
    required int championshipId,
    required String teamName,
  }) async {
    try {
      _error = null;
      notifyListeners();

      if (teamName.trim().isEmpty) {
        _error = 'Nome do time não pode estar vazio';
        notifyListeners();
        return;
      }

      final newTeam = await _repository.createTeam(
        championshipId: championshipId,
        teamName: teamName.trim(),
      );

      _teams.add(newTeam);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadGamesForCurrentRound({
    required int championshipId,
    required int roundNumber,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _games = await _repository.getGamesByRound(
        championshipId: championshipId,
        roundNumber: roundNumber,
      );
    } catch (e) {
      _error = e.toString();
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
      if (timeAId == timeBId) {
        _error = 'Um time não pode jogar contra si mesmo';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final newGame = await _repository.createGame(
        championshipId: championshipId,
        roundsId: roundsId,
        timeAId: timeAId,
        timeBId: timeBId,
      );

      _games.add(newGame);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveAllGames() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updateMultipleGames(_games);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteGame(int gameId) async {
    try {
      await _repository.deleteGame(gameId);
      _games.removeWhere((g) => g.id == gameId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
