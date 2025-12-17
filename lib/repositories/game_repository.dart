import 'package:myapp/models/game.dart';
import 'package:myapp/models/team.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GameRepository {
  final SupabaseClient _client;

  GameRepository(this._client);

  Future<List<Team>> getAllTeams() async {
    try {
      final response = await _client.from('teams').select().order('name');

      return (response as List)
          .map((e) => Team.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar times: $e');
    }
  }

  Future<List<Team>> getTeamsByChampionship(int championshipId) async {
    try {
      final response = await _client
          .from('teams')
          .select()
          .eq('championship_id', championshipId)
          .order('name');

      return (response as List)
          .map((e) => Team.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar times do campeonato: $e');
    }
  }

  Future<Team> createTeam({
    required int championshipId,
    required String teamName,
  }) async {
    try {
      final response = await _client
          .from('teams')
          .insert({'championship_id': championshipId, 'name': teamName})
          .select()
          .single();

      return Team.fromMap(response);
    } catch (e) {
      throw Exception('Erro ao criar time: $e');
    }
  }

  Future<List<Game>> getGamesByChampionship(int championshipId) async {
    try {
      final response = await _client
          .from('games')
          .select()
          .eq('championship_id', championshipId)
          .order('rounds_id');

      return (response as List)
          .map((e) => Game.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar jogos: $e');
    }
  }

  Future<List<Game>> getGamesByRound({
    required int championshipId,
    required int roundNumber,
  }) async {
    try {
      final response = await _client
          .from('games')
          .select()
          .eq('championship_id', championshipId)
          .eq('rounds_id', roundNumber)
          .order('id');

      return (response as List)
          .map((e) => Game.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar jogos da rodada: $e');
    }
  }

  Future<String> getChampionshipOwnerId(int championshipId) async {
    try {
      final response = await _client
          .from('championship')
          .select('owner_id')
          .eq('id', championshipId)
          .single();

      return response['owner_id'] as String;
    } catch (e) {
      throw Exception('Erro ao buscar owner do campeonato: $e');
    }
  }

  Future<Game> createGame({
    required int championshipId,
    required int roundsId,
    required int timeAId,
    required int timeBId,
  }) async {
    try {
      final ownerId = await getChampionshipOwnerId(championshipId);

      final response = await _client
          .from('games')
          .insert({
            'championship_id': championshipId,
            'championshipOwner_id': ownerId,
            'rounds_id': roundsId,
            'time_a_id': timeAId,
            'time_b_id': timeBId,
            'gols_time_A': null,
            'gols_time_B': null,
          })
          .select()
          .single();

      return Game.fromMap(response);
    } catch (e) {
      throw Exception('Erro ao criar jogo: $e');
    }
  }

  Future<void> updateGameScore({
    required int gameId,
    required int scoreA,
    required int scoreB,
  }) async {
    try {
      await _client
          .from('games')
          .update({'gols_time_A': scoreA, 'gols_time_B': scoreB})
          .eq('id', gameId);
    } catch (e) {
      throw Exception('Erro ao atualizar placar: $e');
    }
  }

  Future<void> saveGame(Game game) async {
    try {
      await _client
          .from('games')
          .update({
            'gols_time_A': game.golsTimeA,
            'gols_time_B': game.golsTimeB,
          })
          .eq('id', game.id);
    } catch (e) {
      throw Exception('Erro ao salvar jogo: $e');
    }
  }

  Future<void> updateMultipleGames(List<Game> games) async {
    try {
      for (var game in games) {
        if (game.golsTimeA != null && game.golsTimeB != null) {
          await saveGame(game);
        }
      }
    } catch (e) {
      throw Exception('Erro ao salvar jogos: $e');
    }
  }

  Future<void> deleteGame(int gameId) async {
    try {
      await _client.from('games').delete().eq('id', gameId);
    } catch (e) {
      throw Exception('Erro ao deletar jogo: $e');
    }
  }
}
