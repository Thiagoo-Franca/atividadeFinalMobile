import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:myapp/providers.dart';

class RoundManagementDialog extends ConsumerWidget {
  final int championshipId;

  const RoundManagementDialog({super.key, required this.championshipId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roundController = ref.watch(roundControllerProvider);
    final gameController = ref.watch(gameControllerProvider);

    return AlertDialog(
      title: const Text('Gerenciar Rodadas'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Rodada Atual: ${roundController.currentRound}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Total de Rodadas: ${roundController.totalRounds}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Nova Rodada'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(0, 69, 49, 1),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () async {
              try {
                await roundController.addRound(championshipId);

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Rodada ${roundController.totalRounds} criada! Adicione jogos a ela.',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );

                // Navega para a nova rodada
                while (roundController.currentRound <
                    roundController.totalRounds) {
                  roundController.nextRound();
                }

                await gameController.loadGamesForCurrentRound(
                  championshipId: championshipId,
                  roundNumber: roundController.currentRound,
                );

                if (!context.mounted) return;
                Navigator.pop(context);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao adicionar rodada: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
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
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: roundController.totalRounds > 1
                ? () async {
                    final confirm = await showDialog<bool>(
                      context: context,
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

                    if (confirm != true) return;
                    if (!context.mounted) return;

                    try {
                      final roundToDelete = roundController.currentRound;

                      await roundController.deleteRound(
                        championshipId,
                        roundToDelete,
                      );

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Rodada $roundToDelete excluída com sucesso!',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );

                      await gameController.loadGamesForCurrentRound(
                        championshipId: championshipId,
                        roundNumber: roundController.currentRound,
                      );

                      if (!context.mounted) return;
                      Navigator.pop(context);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao excluir rodada: $e'),
                          backgroundColor: Colors.red,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
