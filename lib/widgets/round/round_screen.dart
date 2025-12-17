import 'package:flutter/material.dart';
import 'package:myapp/controllers/game_controller.dart';
import 'package:myapp/controllers/round_controller.dart';
import 'package:provider/provider.dart';
import 'package:provider/provider.dart' as provider_pkg;
import '../clash_widget.dart';
import '../standings/standings_screen.dart';

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
      final gameController = context.read<GameController>();
      final roundController = context.read<RoundController>();

      roundController.getLastRound(widget.championshipId);
      gameController.loadTeams();
      gameController.loadGamesForCurrentRound(
        championshipId: widget.championshipId,
        roundNumber: roundController.currentRound,
      );
    });
  }

  Future<void> _showAddTeamDialog() async {
    final gameController = context.read<GameController>();
    final teamNameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Novo Time'),
        content: TextField(
          controller: teamNameController,
          decoration: const InputDecoration(
            labelText: 'Nome do Time',
            border: OutlineInputBorder(),
            hintText: 'Digite o nome do time',
          ),
          textCapitalization: TextCapitalization.words,
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
            onPressed: () {
              if (teamNameController.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Criar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && teamNameController.text.trim().isNotEmpty) {
      if (context.mounted) {
        try {
          await gameController.createTeam(
            championshipId: widget.championshipId,
            teamName: teamNameController.text.trim(),
          );

          if (gameController.error == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Time criado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(gameController.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao criar time: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    teamNameController.dispose();
  }

  Future<void> _showAddGameDialog() async {
    final gameController = context.read<GameController>();
    final roundController = context.read<RoundController>();

    if (gameController.teams.isEmpty) {
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
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Time A',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: selectedTeamA,
                    items: gameController.teams.map((team) {
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

                  const Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(0, 69, 49, 1),
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Time B',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: selectedTeamB,
                    items: gameController.teams.map((team) {
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
        await gameController.createGame(
          championshipId: widget.championshipId,
          roundsId: roundController.currentRound,
          timeAId: selectedTeamA!,
          timeBId: selectedTeamB!,
        );

        if (gameController.error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jogo criado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(gameController.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showRoundManagementDialog() async {
    final roundController = context.read<RoundController>();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gerenciar Rodadas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Total de rodadas: ${roundController.totalRounds}',
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
                try {
                  Navigator.pop(dialogContext);
                  await roundController.addRound(widget.championshipId);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Rodada ${roundController.totalRounds} criada! Adicione jogos a ela.',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );

                    while (roundController.currentRound <
                        roundController.totalRounds) {
                      roundController.nextRound();
                    }

                    final gameController = context.read<GameController>();
                    await gameController.loadGamesForCurrentRound(
                      championshipId: widget.championshipId,
                      roundNumber: roundController.currentRound,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao adicionar rodada: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text('Excluir Rodada Atual'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: roundController.totalRounds > 1
                  ? () async {
                      // Confirmação antes de excluir
                      final confirm = await showDialog<bool>(
                        context: dialogContext,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirmar Exclusão'),
                          content: Text(
                            'Deseja realmente excluir a rodada ${roundController.currentRound} e todos os seus jogos?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Excluir'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          Navigator.pop(dialogContext);
                          final roundToDelete = roundController.currentRound;

                          await roundController.deleteRound(
                            widget.championshipId,
                            roundToDelete,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Rodada $roundToDelete excluída com sucesso!',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );

                            final gameController = context
                                .read<GameController>();
                            await gameController.loadGamesForCurrentRound(
                              championshipId: widget.championshipId,
                              roundNumber: roundController.currentRound,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao excluir rodada: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
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
    return provider_pkg.Consumer2<RoundController, GameController>(
      builder: (context, roundController, gameController, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            toolbarHeight: 120,
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
                const SizedBox(height: 20),
              ],
            ),
            backgroundColor: const Color.fromRGBO(0, 69, 49, 1),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.group_add, color: Colors.white),
                onPressed: _showAddTeamDialog,
                tooltip: 'Adicionar Time',
              ),
              IconButton(
                icon: const Icon(Icons.emoji_events, color: Colors.white),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Standings(
                        championshipId: widget.championshipId,
                        championshipName: widget.championshipName,
                      ),
                    ),
                  );
                  final gameController = context.read<GameController>();
                  final roundController = context.read<RoundController>();
                  await gameController.loadGamesForCurrentRound(
                    championshipId: widget.championshipId,
                    roundNumber: roundController.currentRound,
                  );
                },
                tooltip: 'Classificação',
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: _showRoundManagementDialog,
                tooltip: 'Gerenciar Rodadas',
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_outlined),
                      onPressed: roundController.currentRound > 1
                          ? () {
                              roundController.previousRound();
                              gameController.loadGamesForCurrentRound(
                                championshipId: widget.championshipId,
                                roundNumber: roundController.currentRound,
                              );
                            }
                          : null,
                    ),
                    Text(
                      "Rodada ${roundController.currentRound}",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_forward_ios_outlined),
                      onPressed:
                          roundController.currentRound <
                              roundController.totalRounds
                          ? () async {
                              roundController.nextRound();
                              await gameController.loadGamesForCurrentRound(
                                championshipId: widget.championshipId,
                                roundNumber: roundController.currentRound,
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: gameController.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : gameController.error != null
                    ? Center(child: Text('Erro: ${gameController.error}'))
                    : gameController.games.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum jogo nesta rodada',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: gameController.games.length,
                        itemBuilder: (context, index) {
                          final game = gameController.games[index];
                          return Clash(
                            game: game,
                            teamAName: gameController.getTeamName(game.timeAId),
                            teamBName: gameController.getTeamName(game.timeBId),
                          );
                        },
                      ),
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: gameController.isLoading
                      ? null
                      : () async {
                          await gameController.saveAllGames();
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
            tooltip: 'Adicionar Jogo',
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }
}
