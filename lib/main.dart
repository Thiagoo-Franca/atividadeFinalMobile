import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/supabase_config.dart';

// Controllers
import 'controllers/auth_controller.dart';
import 'controllers/championship_controller.dart';
import 'controllers/round_controller.dart';
import 'controllers/game_controller.dart';

// Repositories
import 'repositories/auth_repository.dart';
import 'repositories/championship_repository.dart';
import 'repositories/round_repository.dart';
import 'repositories/game_repository.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController(AuthRepository())),
        ChangeNotifierProvider(
          create: (_) => ChampionshipController(ChampionshipRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => RoundController(RoundRepository()),
        ),
        ChangeNotifierProvider(create: (_) => GameController(GameRepository())),
      ],
      child: const MyApp(),
    ),
  );
}
