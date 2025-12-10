import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/championship_provider.dart';
import '../round/round_screen.dart';

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
      context.read<ChampionshipProvider>().loadChampionshipsForUser();
    });
  }
  Future<void> _showAddChampionshipDialog() async {
    final TextEditingController nameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Campeonato'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nome do campeonato',
            hintText: 'Ex: Champions League 2024',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(0, 69, 49, 1),
            ),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Criar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

if (result == true && nameController.text.trim().isNotEmpty) {
  if (context.mounted) {
    final championshipProvider = context.read<ChampionshipProvider>();
    
    await championshipProvider.createChampionship(nameController.text.trim());
    
    if (championshipProvider.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Campeonato "${nameController.text}" criado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(championshipProvider.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(1, 255, 255, 255),
      appBar: AppBar(
        toolbarHeight: 80,
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
                await context.read<AuthProvider>().signOut();
              }
            },
          ),
        ],
      ),
      body: Consumer<ChampionshipProvider>(
        builder: (context, championshipProvider, child) {
          if (championshipProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (championshipProvider.error != null) {
            return Center(child: Text('Erro: ${championshipProvider.error}'));
          }

          if (championshipProvider.championships.isEmpty) {
            return const Center(child: Text("Nenhum campeonato encontrado."));
          }

          return ListView.builder(
            itemCount: championshipProvider.championships.length,
            itemBuilder: (context, index) {
              final championship = championshipProvider.championships[index];
              return ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 15),
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
        onPressed: _showAddChampionshipDialog,
        backgroundColor: const Color.fromRGBO(0, 69, 49, 1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
