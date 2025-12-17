import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:myapp/providers.dart';
import 'package:myapp/widgets/round/dialogs/add_team_dialog.dart';
import 'package:myapp/widgets/round/dialogs/round_management.dart';
import '../clash_widget.dart';
import '../standings/standings_screen.dart';

class RoundScreen extends HookConsumerWidget {
  final int championshipId;
  final String championshipName;

  const RoundScreen({
    super.key,
    required this.championshipId,
    required this.championshipName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameController = ref.watch(gameControllerProvider);
    final roundController = ref.watch(roundControllerProvider);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        roundController.getLastRound(championshipId);
        gameController.loadTeams();
        gameController.loadGamesForCurrentRound(
          championshipId: championshipId,
          roundNumber: roundController.currentRound,
        );
      });
      return null;
    }, []);

    Future<void> handleAddTeamDialog() async {
      final messenger = ScaffoldMessenger.of(context);
      final controller = ref.read(gameControllerProvider);

      final result = await showDialog<String>(
        context: context,
        builder: (context) => const AddTeamDialog(),
      );

      if (!context.mounted) return;

      if (result != null && result.isNotEmpty) {
        await controller.createTeam(
          championshipId: championshipId,
          teamName: result,
        );

        if (context.mounted) {
          if (controller.error != null) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Erro: ${controller.error}'),
                backgroundColor: Colors.red,
              ),
            );
          } else {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Time criado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    }

    Future<void> showAddGameDialog() async {
      final messenger = ScaffoldMessenger.of(context);
      final controller = ref.read(gameControllerProvider);
      final roundCtrl = ref.read(roundControllerProvider);

      if (controller.teams.isEmpty) {
        messenger.showSnackBar(
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
                      items: controller.teams.map((team) {
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
                      items: controller.teams.map((team) {
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
        await controller.createGame(
          championshipId: championshipId,
          roundsId: roundCtrl.currentRound,
          timeAId: selectedTeamA!,
          timeBId: selectedTeamB!,
        );

        if (context.mounted) {
          if (controller.error == null) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Jogo criado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            messenger.showSnackBar(
              SnackBar(
                content: Text(controller.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }

    Future<void> showRoundManagementDialog() async {
      await showDialog(
        context: context,
        builder: (context) =>
            RoundManagementDialog(championshipId: championshipId),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 120,
        title: Column(
          children: [
            Image.asset('assets/images/EfootRounds.png', height: 50),
            Text(
              championshipName,
              style: const TextStyle(
                color: Color.fromARGB(255, 255, 249, 230),
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
            onPressed: handleAddTeamDialog,
            tooltip: 'Adicionar Time',
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Colors.white),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Standings(
                    championshipId: championshipId,
                    championshipName: championshipName,
                  ),
                ),
              );

              final gameCtrl = ref.read(gameControllerProvider);
              final roundCtrl = ref.read(roundControllerProvider);
              await gameCtrl.loadGamesForCurrentRound(
                championshipId: championshipId,
                roundNumber: roundCtrl.currentRound,
              );
            },
            tooltip: 'Classificação',
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: showRoundManagementDialog,
            tooltip: 'Gerenciar Rodadas',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([gameController, roundController]),
        builder: (context, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_outlined),
                      onPressed: roundController.currentRound > 1
                          ? () {
                              roundController.previousRound();
                              gameController.loadGamesForCurrentRound(
                                championshipId: championshipId,
                                roundNumber: roundController.currentRound,
                              );
                            }
                          : null,
                    ),
                    Text(
                      "Rodada ${roundController.currentRound}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_outlined),
                      onPressed:
                          roundController.currentRound <
                              roundController.totalRounds
                          ? () async {
                              roundController.nextRound();
                              await gameController.loadGamesForCurrentRound(
                                championshipId: championshipId,
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
                    ? const Center(child: CircularProgressIndicator())
                    : gameController.error != null
                    ? Center(child: Text('Erro: ${gameController.error}'))
                    : gameController.games.isEmpty
                    ? const Center(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  onPressed: gameController.isLoading
                      ? null
                      : () async {
                          await gameController.saveAllGames();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Jogos salvos com sucesso!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                  child: const Text(
                    'Salvar Resultados',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddGameDialog,
        backgroundColor: const Color.fromRGBO(0, 69, 49, 1),
        tooltip: 'Adicionar Jogo',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
