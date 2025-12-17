import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:myapp/providers.dart';
import 'package:myapp/widgets/home/dialogs/add_championship_dialog.dart';
import '../round/round_screen.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final championshipController = ref.watch(championshipControllerProvider);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        championshipController.loadChampionships();
      });
      return null;
    }, []);

    Future<void> handleAddChampionship() async {
      final messenger = ScaffoldMessenger.of(context);
      final controller = ref.read(championshipControllerProvider);

      final championshipName = await showDialog<String>(
        context: context,
        builder: (context) => const AddChampionshipDialog(),
      );

      if (championshipName != null && context.mounted) {
        await controller.createChampionship(championshipName);

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
                content: Text('Campeonato criado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(1, 255, 255, 255),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 120,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Image.asset('assets/images/EfootRounds.png', height: 50)],
        ),
        backgroundColor: const Color.fromRGBO(0, 69, 49, 1),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sair'),
                  content: const Text('Deseja realmente fazer logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await ref.read(authControllerProvider).signOut();
              }
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: championshipController,
        builder: (context, _) {
          if (championshipController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (championshipController.error != null) {
            return Center(child: Text('Erro: ${championshipController.error}'));
          }

          if (championshipController.championships.isEmpty) {
            return const Center(child: Text("Nenhum campeonato encontrado."));
          }

          return ListView.builder(
            itemCount: championshipController.championships.length,
            itemBuilder: (context, index) {
              final championship = championshipController.championships[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                tileColor: const Color.fromARGB(255, 216, 216, 216),
                iconColor: const Color.fromRGBO(0, 69, 49, 1),
                title: Text(
                  championship.name,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Color.fromRGBO(0, 69, 49, 1),
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Color.fromRGBO(0, 69, 49, 1),
                ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: handleAddChampionship,
        backgroundColor: const Color.fromRGBO(0, 69, 49, 1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
