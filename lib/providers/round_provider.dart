import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoundProvider extends ChangeNotifier {
  int _currentRound = 1;
  int _totalRounds = 0;
  bool _isLoading = false;

  int get currentRound => _currentRound;
  int get totalRounds => _totalRounds;
  bool get isLoading => _isLoading;

  // Carrega o número total de rodadas do banco de dados
  Future<void> loadRounds(int championshipId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('rounds')
          .select('round_number')
          .eq('championship_id', championshipId)
          .order('round_number', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        _totalRounds = response.first['round_number'] as int;
      } else {
        _totalRounds = 0;
      }
    } catch (e) {
      print('Erro ao carregar rodadas: $e');
      _totalRounds = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

  Future<void> addRound(int championshipId) async {
    try {
      await Supabase.instance.client.from('rounds').insert({
        'championship_id': championshipId,
        'round_number': _totalRounds + 1,
      });
      _totalRounds++;
      notifyListeners();
    } catch (e) {
      print('Erro ao adicionar rodada: $e');
      rethrow;
    }
  }

  Future<void> deleteRound(int championshipId, int roundNumber) async {
    if (_totalRounds <= 1) {
      print('Não é possível excluir a última rodada');
      return;
    }

    try {
      // Primeiro, exclui os jogos da rodada
      await Supabase.instance.client
          .from('games')
          .delete()
          .eq('championship_id', championshipId)
          .eq('rounds_id', roundNumber);

      // Depois, exclui a rodada
      await Supabase.instance.client
          .from('rounds')
          .delete()
          .eq('championship_id', championshipId)
          .eq('round_number', roundNumber);

      _totalRounds--;

      // Se a rodada atual for maior que o total, volte para a última rodada
      if (_currentRound > _totalRounds) {
        _currentRound = _totalRounds;
      }

      notifyListeners();
    } catch (e) {
      print('Erro ao excluir rodada: $e');
      rethrow;
    }
  }

  void reset() {
    _currentRound = 1;
    _totalRounds = 0;
    notifyListeners();
  }
}
