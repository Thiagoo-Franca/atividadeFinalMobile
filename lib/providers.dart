import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:myapp/controllers/auth_controller.dart';
import 'package:myapp/controllers/championship_controller.dart';
import 'package:myapp/controllers/game_controller.dart';
import 'package:myapp/controllers/round_controller.dart';
import 'package:myapp/repositories/auth_repository.dart';
import 'package:myapp/repositories/championship_repository.dart';
import 'package:myapp/repositories/game_repository.dart';
import 'package:myapp/repositories/round_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'providers.g.dart';

// Repositories
@riverpod
SupabaseClient supabaseClient(ref) {
  return Supabase.instance.client;
}

@riverpod
AuthRepository authRepository(ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
}

@riverpod
ChampionshipRepository championshipRepository(ref) {
  return ChampionshipRepository(ref.watch(supabaseClientProvider));
}

@riverpod
RoundRepository roundRepository(ref) {
  return RoundRepository(ref.watch(supabaseClientProvider));
}

@riverpod
GameRepository gameRepository(ref) {
  return GameRepository(ref.watch(supabaseClientProvider));
}

// Controllers
@riverpod
AuthController authController(ref) {
  return AuthController(ref.watch(authRepositoryProvider));
}

@riverpod
ChampionshipController championshipController(ref) {
  return ChampionshipController(ref.watch(championshipRepositoryProvider));
}

@riverpod
RoundController roundController(ref) {
  return RoundController(ref.watch(roundRepositoryProvider));
}

@riverpod
GameController gameController(ref) {
  return GameController(ref.watch(gameRepositoryProvider));
}
