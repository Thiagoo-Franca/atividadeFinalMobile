import 'package:flutter/material.dart';
import 'package:myapp/providers/game_provider.dart';
import 'package:myapp/providers/round_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/provider.dart' as provider_pkg;
import '../../widgets/clash_widget.dart';

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

      roundProvider.loadRounds(widget.championshipId);
      gameProvider.loadTeams();
      gameProvider.loadGamesForCurrentRound(
        widget.championshipId,
        roundProvider.currentRound,
      );
    });
  }

  Future<void> _showAddGameDialog() async {
    final gameProvider = context.read<GameProvider>();
    final roundProvider = context.read<RoundProvider>();

    if (gameProvider.teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum time disponível. Cadastre times primeiro.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int? selectedTeamA;
    int? selectedTeamB;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Novo Jogo'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dropdown Time A
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Time A',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedTeamA,
                    items: gameProvider.teams.map((team) {
                      return DropdownMenuItem<int>(
                        value: team.id,
                        child: Text(team.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedTeamA = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // VS
                  const Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(0, 69, 49, 1),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dropdown Time B
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Time B',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedTeamB,
                    items: gameProvider.teams.map((team) {
                      return DropdownMenuItem<int>(
                        value: team.id,
                        child: Text(team.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedTeamB = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(0, 69, 49, 1),
                ),
                onPressed:
                    selectedTeamA != null &&
                        selectedTeamB != null &&
                        selectedTeamA != selectedTeamB
                    ? () => Navigator.pop(dialogContext, true)
                    : null,
                child: const Text(
                  'Criar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && selectedTeamA != null && selectedTeamB != null) {
      if (context.mounted) {
        await gameProvider.createGame(
          championshipId: widget.championshipId,
          roundsId: roundProvider.currentRound,
          timeAId: selectedTeamA!,
          timeBId: selectedTeamB!,
        );

        if (gameProvider.error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jogo criado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(gameProvider.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showRoundManagementDialog() async {
    final roundProvider = context.read<RoundProvider>();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gerenciar Rodadas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Total de rodadas: ${roundProvider.totalRounds}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Nova Rodada'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(0, 69, 49, 1),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await roundProvider.addRound(widget.championshipId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rodada adicionada com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text('Excluir Última Rodada'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: roundProvider.totalRounds > 1
                  ? () async {
                      Navigator.pop(dialogContext);
                      await roundProvider.deleteRound(
                        widget.championshipId,
                        roundProvider.totalRounds,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Rodada excluída com sucesso!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  : null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return provider_pkg.Consumer2<RoundProvider, GameProvider>(
      builder: (context, roundProvider, gameProvider, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            toolbarHeight: 80,
            title: Column(
              children: [
                Image.asset('assets/images/EfootRounds.png', height: 50),
                Text(
                  widget.championshipName,
                  style: TextStyle(
                    color: const Color.fromARGB(255, 255, 249, 230),
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color.fromRGBO(0, 69, 49, 1),
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
                                widget.championshipId,
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
                                widget.championshipId,
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
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddGameDialog,
            backgroundColor: const Color.fromRGBO(0, 69, 49, 1),
            child: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Adicionar Jogo',
          ),
        );
      },
    );
  }
}
