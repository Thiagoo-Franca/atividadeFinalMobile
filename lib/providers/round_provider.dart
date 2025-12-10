import 'package:flutter/material.dart';

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
