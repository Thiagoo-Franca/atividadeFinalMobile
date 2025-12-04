import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:app_links/app_links.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  User? _user;
  late final AppLinks _appLinks;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;

  AuthProvider() {
    if (!kIsWeb) {
      _appLinks = AppLinks();
      _initDeepLinks();
    }

    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      _isAuthenticated = session != null;
      _user = session?.user;

      if (session != null) {
        print('User signed in: ${_user?.email}');
        await _ensureExists(session.user);
      }
      _isLoading = false;
      notifyListeners();
    });
    _checkAuthStatus();
  }

  void _initDeepLinks() {
    _appLinks.uriLinkStream.listen((Uri? uri) {
      print('Received deep link: $uri');
      if (uri != null) {
        print('Deep link received: $uri');
        _handleDeepLink(uri);
      }
    });
  }

  void _handleDeepLink(Uri uri) async {
    if (uri.scheme == 'myapp' && uri.host == 'login-callback') {
      print('OAuth callback detected');
    }
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = Supabase.instance.client.auth.currentSession;
      _isAuthenticated = session != null;
      _user = session?.user;
      print('Session check - authenticated: $_isAuthenticated');
    } catch (e) {
      _error = 'Erro ao verificar status de autenticação: $e';
      print('Error checking auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _ensureExists(User authUser) async {
    try {
      final response = await Supabase.instance.client
          .from('user')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();
      if (response == null) {
        print('Creating user record for ${authUser.email}');
        await Supabase.instance.client.from('user').insert({
          'id': authUser.id,
          'email': authUser.email,
          'name':
              authUser.userMetadata?['name'] ??
              authUser.email?.split('@')[0] ??
              'Usuario',
        });
        print('User record created for ${authUser.email}');
      } else {
        print('User record already exists for ${authUser.email}');
      }
    } catch (e) {
      print('Error ensuring user exists: $e');
      _error = 'Erro ao garantir existência do usuário: $e';
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Iniciando login com Google...');

      if (kIsWeb) {
        // Para web, não precisa de redirectTo customizado
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: Uri.base.origin,
        );
      } else {
        // Para mobile
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'myapp://login-callback',
          authScreenLaunchMode: LaunchMode.externalApplication,
        );
      }

      print('OAuth initiated successfully');
      return true;
    } catch (e) {
      _error = 'Erro ao fazer login com Google: $e';
      print('Erro no login com Google: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () async {
            final success = await authProvider.signInWithGoogle();
            if (!success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(authProvider.error ?? 'Erro desconhecido'),
                ),
              );
            }
          },
          icon: Icon(Icons.g_mobiledata, size: 24),
          label: Text('Login com Google'),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (authProvider.isAuthenticated) {
      return HomeScreen();
    } else {
      return LoginScreen();
    }
  }
}

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
}

class GameProvider extends ChangeNotifier {
  List<Game> _games = [];
  List<Team> _teams = [];
  bool _isLoading = false;
  String? _error;

  List<Game> get games => _games;
  List<Team> get teams => _teams;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String getTeamName(int teamId) {
    try {
      return _teams.firstWhere((team) => team.id == teamId).name;
    } catch (e) {
      return 'Time $teamId';
    }
  }

  Future<void> loadGames() async {
    try {
      final results = await Supabase.instance.client.from('teams').select();
      _teams = (results as List).map((e) => Team.fromMap(e)).toList();
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao buscar dados: $e';
      notifyListeners();
    }
  }

  Future<void> loadGamesForCurrentRound(int roundNumber) async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Supabase.instance.client
          .from('games')
          .select()
          .eq('rounds_id', roundNumber);

      _games = (results as List).map((e) => Game.fromMap(e)).toList();
      if (_games.isEmpty) {
        print('No games found for round $roundNumber');
      } else {
        print('Games found for round $roundNumber: ${_games.length}');
      }
      print('Games loaded for round $roundNumber: ${_games.length}');
      _error = null;
    } catch (e) {
      _error = 'Erro ao buscar dados: $e';
      print('Error loading games for round $roundNumber: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateGameResultLocally(int gameId, int golsTimeA, int golsTimeB) {
    try {
      final gameIndex = _games.indexWhere((game) => game.id == gameId);
      if (gameIndex != -1) {
        _games[gameIndex].golsTimeA = golsTimeA;
        _games[gameIndex].golsTimeB = golsTimeB;
        notifyListeners();
      } else {
        print('Game with id $gameId not found.');
      }
    } catch (e) {
      print('Error updating game result locally: $e');
    }
  }

  Future<void> saveAllGames() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      for (var game in _games) {
        await Supabase.instance.client
            .from('games')
            .update({
              'gols_time_A': game.golsTimeA,
              'gols_time_B': game.golsTimeB,
            })
            .eq('id', game.id);
      }
      print('Todos jogos salvos com sucesso!');
    } catch (e) {
      _error = 'Erro ao salvar jogos: $e';
      print('Erro ao salvar jogos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class AppUser {
  final String id;
  final String name;
  final String email;

  AppUser({required this.id, required this.name, required this.email});

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    id: map['id'] as String,
    name: map['name'] as String,
    email: map['email'] as String,
  );
}

class Championship {
  final int id;
  final String name;

  Championship({required this.id, required this.name});

  factory Championship.fromMap(Map<String, dynamic> map) =>
      Championship(id: map['id'] as int, name: map['name'] as String);
}

class Team {
  final int id;
  final String name;

  Team({required this.id, required this.name});

  factory Team.fromMap(Map<String, dynamic> map) =>
      Team(id: map['id'] as int, name: map['name'] as String);
}

class Game {
  final int id;
  final int roundsId;
  final int timeAId;
  final int timeBId;
  final String championshipOwnerId;
  int? golsTimeA;
  int? golsTimeB;

  Game({
    required this.id,
    required this.roundsId,
    required this.timeAId,
    required this.timeBId,
    required this.championshipOwnerId,
    this.golsTimeA,
    this.golsTimeB,
  });

  factory Game.fromMap(Map<String, dynamic> map) {
    print('Mapping Game from map: $map');
    return Game(
      id: map['id'] is int ? map['id'] : int.parse(map['id'].toString()),
      roundsId: map['rounds_id'] is int
          ? map['rounds_id']
          : int.parse(map['rounds_id'].toString()),
      timeAId: map['time_a_id'] is int
          ? map['time_a_id']
          : int.parse(map['time_a_id'].toString()),
      timeBId: map['time_b_id'] is int
          ? map['time_b_id']
          : int.parse(map['time_b_id'].toString()),
      golsTimeA: map['gols_time_A'] == null
          ? null
          : (map['gols_time_A'] is int
                ? map['gols_time_A']
                : int.parse(map['gols_time_A'].toString())),
      golsTimeB: map['gols_time_B'] == null
          ? null
          : (map['gols_time_B'] is int
                ? map['gols_time_B']
                : int.parse(map['gols_time_B'].toString())),
      championshipOwnerId: map['championshipOwner_id'] as String,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://douwctlommhpagyfdanb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvdXdjdGxvbW1ocGFneWZkYW5iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwOTA0NzAsImV4cCI6MjA3OTY2NjQ3MH0.MOQddEYhLsaNgGc7tkdokMlQqL9olI0hV-qJsnBBwCs',
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce, // ADICIONE
    ),
  );
  /*
  await Supabase.instance.client.from('Equipe').insert([
    {'id': 1, 'name': 'Time A'},
    {'id': 2, 'name': 'Time B'},
    {'id': 3, 'name': 'Time C'},
    {'id': 4, 'name': 'Time D'},
  ]);
  await Supabase.instance.client.from('matches').insert([
    {'id': 1, 'number': 1},
    {'id': 2, 'number': 2},
    {'id': 3, 'number': 3},
  ]);
  await Supabase.instance.client.from('match').insert([
    {'id': 1, 'matches_id': 1, 'time_a_id': 1, 'time_b_id': 2},

    {'id': 2, 'matches_id': 1, 'time_a_id': 3, 'time_b_id': 4},
    {'id': 3, 'matches_id': 2, 'time_a_id': 1, 'time_b_id': 3},
    {'id': 4, 'matches_id': 2, 'time_a_id': 2, 'time_b_id': 4},
  ]);
  await Supabase.instance.client.from('championship').insert({
    'id': 1,
    'name': 'campeonato de teste',
    'owner_id': 'ec5a3238-e307-4cfd-90d9-970619934722',
  });
*/

  try {
    final results = await Supabase.instance.client.from('teams').select();

    final teams = (results as List).map((e) => Team.fromMap(e)).toList();

    print('Times:  ${teams.length}');
    for (var team in teams) {
      print('Time: id=${team.id}, name=${team.name}');
    }
  } catch (e) {
    print('Erro ao buscar dados: $e');
  }

  try {
    final currentUser = Supabase.instance.client.auth.currentUser;

    final results = await Supabase.instance.client.from('games').select();

    if (currentUser != null) {
      final championships = await Supabase.instance.client
          .from('championship')
          .select()
          .eq('owner_id', currentUser.id);

      for (var champ in championships) {
        print('Championship owned: id=${champ['id']}, name=${champ['name']}');
      }
    } else {
      print('Nenhum usuário logado');
    }
  } catch (e) {
    print('Erro ao buscar dados: $e');
  }

  try {
    final results = await Supabase.instance.client.from('games').select();

    final games = (results as List).map((e) => Game.fromMap(e)).toList();
    print('Dados da tabela games: ${games.length}');
    for (var game in games) {
      print(
        'Game: id=${game.id}, rounds_id=${game.roundsId}, time_a_id=${game.timeAId}, time_b_id=${game.timeBId}, gols_time_A=${game.golsTimeA}, gols_time_B=${game.golsTimeB}',
      );
    }
  } catch (e) {
    print('Erro ao buscar dados: $e');
  }

  runApp(
    provider_pkg.MultiProvider(
      providers: [
        provider_pkg.ChangeNotifierProvider(create: (_) => AuthProvider()),
        provider_pkg.ChangeNotifierProvider(
          create: (_) => ChampionshipProvider(),
        ),
        provider_pkg.ChangeNotifierProvider(create: (_) => RoundProvider()),
        provider_pkg.ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eFootRounds',
      theme: ThemeData(useMaterial3: true),
      home: const AuthWrapper(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final championshipProvider = context.read<ChampionshipProvider>();
      championshipProvider.loadChampionshipsForUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "eFootRounds",
          style: TextStyle(
            color: const Color.fromARGB(255, 255, 249, 230),
            fontSize: 32,
          ),
        ),
        backgroundColor: Colors.red[400],
        centerTitle: true,
      ),
      body: provider_pkg.Consumer<ChampionshipProvider>(
        builder: (context, championshipProvider, child) {
          if (championshipProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (championshipProvider.error != null) {
            return Center(child: Text('Erro: ${championshipProvider.error}'));
          }

          if (championshipProvider.championships.isEmpty) {
            return Center(child: Text("Nenhum campeonato encontrado."));
          }

          return ListView.builder(
            itemCount: championshipProvider.championships.length,
            itemBuilder: (context, index) {
              final championship = championshipProvider.championships[index];
              return ListTile(
                title: Text(championship.name, style: TextStyle(fontSize: 20)),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoundScreen(
                        championshipId: championship.id,
                        championshipName: championship.name,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class RoundScreen extends StatefulWidget {
  final int championshipId;
  final String championshipName;

  const RoundScreen({
    super.key,
    required this.championshipId,
    required this.championshipName,
  });

  @override
  State<RoundScreen> createState() => _RoundScreenState();
}

class _RoundScreenState extends State<RoundScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = context.read<GameProvider>();
      final roundProvider = context.read<RoundProvider>();

      gameProvider.loadGames();
      gameProvider.loadGamesForCurrentRound(roundProvider.currentRound);
    });
  }

  @override
  Widget build(BuildContext context) {
    return provider_pkg.Consumer2<RoundProvider, GameProvider>(
      builder: (context, roundProvider, gameProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.championshipName,
              style: TextStyle(
                color: const Color.fromARGB(255, 255, 249, 230),
                fontSize: 24,
              ),
            ),
            backgroundColor: Colors.red[400],
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Navegação de rodadas
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_outlined),
                      onPressed: roundProvider.currentRound > 1
                          ? () {
                              roundProvider.previousRound();
                              gameProvider.loadGamesForCurrentRound(
                                roundProvider.currentRound,
                              );
                            }
                          : null,
                    ),
                    Text(
                      "Rodada ${roundProvider.currentRound}",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios_outlined),
                      onPressed:
                          roundProvider.currentRound < roundProvider.totalRounds
                          ? () {
                              roundProvider.nextRound();
                              gameProvider.loadGamesForCurrentRound(
                                roundProvider.currentRound,
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ),

              // Lista de jogos
              Expanded(
                child: gameProvider.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : gameProvider.error != null
                    ? Center(child: Text('Erro: ${gameProvider.error}'))
                    : gameProvider.games.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum jogo nesta rodada',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: gameProvider.games.length,
                        itemBuilder: (context, index) {
                          final game = gameProvider.games[index];
                          return Clash(
                            game: game,
                            teamAName: gameProvider.getTeamName(game.timeAId),
                            teamBName: gameProvider.getTeamName(game.timeBId),
                          );
                        },
                      ),
              ),

              // Botão salvar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: gameProvider.isLoading
                      ? null
                      : () async {
                          await gameProvider.saveAllGames();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Jogos salvos com sucesso!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                  child: Text(
                    'Salvar Resultados',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class Clash extends StatelessWidget {
  final Game game;
  final String teamAName;
  final String teamBName;

  const Clash({
    super.key,
    required this.game,
    required this.teamAName,
    required this.teamBName,
  });

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.read<GameProvider>();

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              teamAName,
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
            SizedBox(
              height: 32,
              width: 32,
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                controller: TextEditingController(
                  text: game.golsTimeA?.toString() ?? '',
                ),
                onChanged: (value) {
                  final gols = int.tryParse(value);
                  gameProvider.updateGameResultLocally(
                    game.id,
                    gols ?? 0,
                    game.golsTimeB ?? 0,
                  );
                },
              ),
            ),
            Text("X", style: TextStyle(color: Colors.black, fontSize: 16)),
            SizedBox(
              height: 32,
              width: 32,
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                controller: TextEditingController(
                  text: game.golsTimeB?.toString() ?? '',
                ),
                onChanged: (value) {
                  final gols = int.tryParse(value);
                  gameProvider.updateGameResultLocally(
                    game.id,
                    game.golsTimeA ?? 0,
                    gols ?? 0,
                  );
                },
              ),
            ),
            Text(
              teamBName,
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class Championships extends StatelessWidget {
  final List<Championship> championships;
  final Function(Championship) onTap;

  const Championships({
    super.key,
    required this.championships,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: championships.map((championship) {
        return ListTile(
          title: Text(championship.name),
          onTap: () => onTap(championship),
        );
      }).toList(),
    );
  }
}
