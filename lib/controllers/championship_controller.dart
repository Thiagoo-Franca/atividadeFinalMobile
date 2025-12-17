import 'package:flutter/material.dart';
import '../models/championship.dart';
import '../repositories/championship_repository.dart';

class ChampionshipController extends ChangeNotifier {
  final ChampionshipRepository _repository;

  List<Championship> _championships = [];
  bool _isLoading = false;
  String? _error;

  List<Championship> get championships => _championships;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ChampionshipController(this._repository);

  Future<void> loadChampionships() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _repository.getCurrentUserId();

      if (userId == null) {
        _error = 'Usuário não autenticado';
        _championships = [];
      } else {
        _championships = await _repository.getChampionshipsByUser(userId);
      }
    } catch (e) {
      _error = 'Erro ao carregar campeonatos: $e';
      _championships = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createChampionship(String name) async {
    if (name.trim().isEmpty) {
      _error = 'Nome do campeonato não pode estar vazio';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _repository.getCurrentUserId();

      if (userId == null) {
        _error = 'Usuário não autenticado';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final newChampionship = await _repository.createChampionship(
        name.trim(),
        userId,
      );

      _championships.insert(0, newChampionship);

      return true;
    } catch (e) {
      _error = 'Erro ao criar campeonato: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteChampionship(int championshipId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteChampionship(championshipId);

      _championships.removeWhere((c) => c.id == championshipId);

      return true;
    } catch (e) {
      _error = 'Erro ao deletar campeonato: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateChampionship(int championshipId, String newName) async {
    if (newName.trim().isEmpty) {
      _error = 'Nome do campeonato não pode estar vazio';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedChampionship = await _repository.updateChampionship(
        championshipId,
        newName.trim(),
      );

      final index = _championships.indexWhere((c) => c.id == championshipId);
      if (index != -1) {
        _championships[index] = updatedChampionship;
      }

      return true;
    } catch (e) {
      _error = 'Erro ao atualizar campeonato: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
