import 'package:supabase_flutter/supabase_flutter.dart';

class RoundRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<int> getLastRound(int championshipId) async {
    try {
      final response = await _client
          .from('games')
          .select('rounds_id')
          .eq('championship_id', championshipId)
          .order('rounds_id', ascending: false)
          .limit(1);
      if (response.isEmpty) {
        return 0;
      }
      return response.first['rounds_id'] as int;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteRound(int championshipId, int roundNumber) async {
    try {
      await _client
          .from('games')
          .delete()
          .eq('championship_id', championshipId)
          .eq('rounds_id', roundNumber);
    } catch (e) {
      rethrow;
    }
  }
}
