import 'package:myapp/models/championship.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChampionshipRepository {
  final SupabaseClient _client = Supabase.instance.client;

  String? getCurrentUserId() {
    try {
      final user = _client.auth.currentUser;
      return user?.id;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final response = await _client
          .from('user')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  Future<List<Championship>> getChampionshipsByUser(String userId) async {
    try {
      final results = await _client
          .from('championship')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      return (results as List).map((e) => Championship.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Failed to get championships: $e');
    }
  }

  Future<Championship> createChampionship(String name, String ownerId) async {
    try {
      final response = await _client
          .from('championship')
          .insert({'name': name, 'owner_id': ownerId})
          .select()
          .single();

      return Championship.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create championship: $e');
    }
  }

  Future<void> deleteChampionship(int championshipId) async {
    try {
      await _client.from('championship').delete().eq('id', championshipId);
    } catch (e) {
      throw Exception('Failed to delete championship: $e');
    }
  }

  Future<Championship> updateChampionship(
    int championshipId,
    String name,
  ) async {
    try {
      final response = await _client
          .from('championship')
          .update({'name': name})
          .eq('id', championshipId)
          .select()
          .single();

      return Championship.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update championship: $e');
    }
  }
}
