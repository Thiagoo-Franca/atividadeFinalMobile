import 'package:flutter/material.dart';
import 'package:myapp/models/championship.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChampionshipProvider extends ChangeNotifier {
  List<Championship> _championships = [];
  bool _isLoading = false;
  String? _error;

  List<Championship> get championships => _championships;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadChampionshipsForUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        _error = 'Nenhum usuário logado';
        _championships = [];
        return;
      }
      print('Loading championships for user: ${currentUser.id}');

      final results = await Supabase.instance.client
          .from('championship')
          .select()
          .eq('owner_id', currentUser.id);

      _championships = (results as List)
          .map((e) => Championship.fromMap(e))
          .toList();
      print('Championships loaded: ${_championships.length}');

      _error = null;
    } catch (e) {
      _error = 'Erro ao buscar campeonatos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createChampionship(String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        _error = 'Nenhum usuário logado';
        return;
      }

      print('Creating championship: $name');

      final response = await Supabase.instance.client
          .from('championship')
          .insert({'name': name, 'owner_id': currentUser.id})
          .select()
          .single();

      final newChampionship = Championship.fromMap(response);
      _championships.add(newChampionship);

      print('Championship created: ${newChampionship.id}');
      _error = null;
    } catch (e) {
      _error = 'Erro ao criar campeonato: $e';
      print('Error creating championship: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
