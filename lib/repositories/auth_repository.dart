import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  GoTrueClient get auth => _client.auth;

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await _client
          .from('user')
          .select()
          .eq('id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createUser({
    required String id,
    required String email,
    required String name,
  }) async {
    try {
      await _client.from('user').insert({
        'id': id,
        'email': email,
        'name': name,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithGoogle({
    required String redirectTo,
    LaunchMode? authScreenLaunchMode,
  }) async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        authScreenLaunchMode:
            authScreenLaunchMode ?? LaunchMode.platformDefault,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut(scope: SignOutScope.global);
    } catch (e) {
      rethrow;
    }
  }

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
}
