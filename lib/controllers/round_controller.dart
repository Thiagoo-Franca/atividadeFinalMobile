import 'package:flutter/material.dart';
import 'package:myapp/repositories/round_repository.dart';

class RoundController extends ChangeNotifier {
  final RoundRepository _repository;
  bool _isLoading = false;

  RoundController(this._repository);

  int _currentRound = 1;
  int _totalRounds = 0;

  int get currentRound => _currentRound;
  int get totalRounds => _totalRounds;
  bool get isLoading => _isLoading;

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

  void reset() {
    _currentRound = 1;
    _totalRounds = 0;
    notifyListeners();
  }

  Future<void> addRound(int championshipId) async {
    try {
      _totalRounds++;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteRound(int championshipId, int roundNumber) async {
    if (_totalRounds <= 1) {
      return;
    }
    try {
      await _repository.deleteRound(championshipId, roundNumber);
      _totalRounds--;

      if (_currentRound > _totalRounds) {
        _currentRound = _totalRounds;
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getLastRound(int championshipId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final lastRound = await _repository.getLastRound(championshipId);

      if (lastRound != 0) {
        _totalRounds = lastRound;
      } else {
        _totalRounds = 0;
      }
      return lastRound;
    } catch (e) {
      _totalRounds = 0;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
