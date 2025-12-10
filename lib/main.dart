import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/championship_provider.dart';
import 'providers/round_provider.dart';
import 'providers/game_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChampionshipProvider()),
        ChangeNotifierProvider(create: (_) => RoundProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: const MyApp(),
    ),
  );
}
