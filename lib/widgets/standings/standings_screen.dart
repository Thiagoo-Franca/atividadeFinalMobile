import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeamStanding {
  final int teamId;
  final String teamName;
  int points = 0;
  int played = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;

  TeamStanding({required this.teamId, required this.teamName});

  int get goalDifference => goalsFor - goalsAgainst;
}

class Standings extends HookConsumerWidget {
  final int championshipId;
  final String championshipName;

  const Standings({
    super.key,
    required this.championshipId,
    required this.championshipName,
  });

  Future<List<TeamStanding>> _loadStandings() async {
    final teamsResponse = await Supabase.instance.client
        .from('teams')
        .select('id, name')
        .eq('championship_id', championshipId);

    final gamesResponse = await Supabase.instance.client
        .from('games')
        .select('time_a_id, time_b_id, gols_time_A, gols_time_B')
        .eq('championship_id', championshipId)
        .not('gols_time_A', 'is', null)
        .not('gols_time_B', 'is', null);

    Map<int, TeamStanding> standingsMap = {};

    for (var team in teamsResponse) {
      standingsMap[team['id']] = TeamStanding(
        teamId: team['id'],
        teamName: team['name'],
      );
    }

    for (var game in gamesResponse) {
      final timeAId = game['time_a_id'] as int;
      final timeBId = game['time_b_id'] as int;
      final timeAScore = game['gols_time_A'] as int;
      final timeBScore = game['gols_time_B'] as int;

      final teamA = standingsMap[timeAId];
      final teamB = standingsMap[timeBId];

      if (teamA != null && teamB != null) {
        teamA.played += 1;
        teamB.played += 1;

        teamA.goalsFor += timeAScore;
        teamA.goalsAgainst += timeBScore;
        teamB.goalsFor += timeBScore;
        teamB.goalsAgainst += timeAScore;

        if (timeAScore > timeBScore) {
          teamA.wins += 1;
          teamA.points += 3;
          teamB.losses += 1;
        } else if (timeAScore < timeBScore) {
          teamB.wins += 1;
          teamB.points += 3;
          teamA.losses += 1;
        } else {
          teamA.draws += 1;
          teamB.draws += 1;
          teamA.points += 1;
          teamB.points += 1;
        }
      }
    }

    List<TeamStanding> standingsList = standingsMap.values.toList();
    standingsList.sort((a, b) {
      if (b.points != a.points) {
        return b.points.compareTo(a.points);
      } else if (b.goalDifference != a.goalDifference) {
        return b.goalDifference.compareTo(a.goalDifference);
      } else {
        return b.goalsFor.compareTo(a.goalsFor);
      }
    });

    return standingsList;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsFuture = useMemoized(() => _loadStandings(), [
      championshipId,
    ]);
    final standingsSnapshot = useFuture(standingsFuture);

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
          ],
        ),
        backgroundColor: const Color.fromRGBO(0, 69, 49, 1),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // Força recarregar recriando o Future
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => Standings(
                    championshipId: championshipId,
                    championshipName: championshipName,
                  ),
                ),
              );
            },
            tooltip: 'Atualizar Classificação',
          ),
        ],
      ),
      body: standingsSnapshot.connectionState == ConnectionState.waiting
          ? const Center(child: CircularProgressIndicator())
          : standingsSnapshot.hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    standingsSnapshot.error.toString(),
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Standings(
                            championshipId: championshipId,
                            championshipName: championshipName,
                          ),
                        ),
                      );
                    },
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            )
          : standingsSnapshot.data?.isEmpty ?? true
          ? const Center(child: Text('Nenhum jogo finalizado ainda.'))
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Cabeçalho da tabela
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    color: const Color.fromRGBO(0, 69, 49, 0.1),
                    child: Row(
                      children: const [
                        SizedBox(
                          width: 40,
                          child: Text(
                            '#',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Time',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            'P',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            'J',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            'V',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            'E',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            'D',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            'SG',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Lista de times
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: standingsSnapshot.data!.length,
                    itemBuilder: (context, index) {
                      final standing = standingsSnapshot.data![index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${index + 1}º',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                standing.teamName,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${standing.points}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${standing.played}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${standing.wins}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${standing.draws}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${standing.losses}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${standing.goalDifference >= 0 ? '+' : ''}${standing.goalDifference}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: standing.goalDifference > 0
                                      ? Colors.green
                                      : standing.goalDifference < 0
                                      ? Colors.red
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
