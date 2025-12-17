import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

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

  Future<void> _downloadStandings(
    BuildContext context,
    GlobalKey repaintKey,
  ) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      final RenderRepaintBoundary boundary =
          repaintKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (!context.mounted) return;
      Navigator.pop(context);

      if (byteData == null) {
        throw Exception('Erro ao capturar imagem');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final blob = web.Blob([pngBytes.toJS].toJS);
      final url = web.URL.createObjectURL(blob);
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
      anchor.href = url;
      anchor.download =
          'classificacao_${championshipName.replaceAll(' ', '_')}.png';
      anchor.click();
      web.URL.revokeObjectURL(url);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imagem baixada com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao baixar: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repaintKey = useMemoized(() => GlobalKey());

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
          if (standingsSnapshot.hasData && standingsSnapshot.data!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: () => _downloadStandings(context, repaintKey),
              tooltip: 'Baixar Classificação',
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
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
          : RepaintBoundary(
              key: repaintKey,
              child: Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(
                          color: Color.fromRGBO(0, 69, 49, 0.1),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 50,
                              child: Text(
                                '#',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 45,
                              child: Text(
                                'P',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 45,
                              child: Text(
                                'J',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 45,
                              child: Text(
                                'V',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 45,
                              child: Text(
                                'E',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 45,
                              child: Text(
                                'D',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 45,
                              child: Text(
                                'SG',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: standingsSnapshot.data!.length,
                        itemBuilder: (context, index) {
                          final standing = standingsSnapshot.data![index];
                          final position = index + 1;

                          Color? backgroundColor;
                          Widget? positionIcon;

                          if (position == 1) {
                            backgroundColor = Colors.amber.shade100;
                            positionIcon = const Icon(
                              Icons.emoji_events,
                              color: Colors.amber,
                              size: 20,
                            );
                          } else if (position == 2) {
                            backgroundColor = Colors.grey.shade200;
                            positionIcon = const Icon(
                              Icons.workspace_premium,
                              color: Colors.grey,
                              size: 20,
                            );
                          } else if (position == 3) {
                            backgroundColor = Colors.orange.shade100;
                            positionIcon = const Icon(
                              Icons.workspace_premium,
                              color: Colors.orange,
                              size: 20,
                            );
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 50,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$positionº',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (positionIcon != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 4,
                                          ),
                                          child: positionIcon,
                                        ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    standing.teamName,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                SizedBox(
                                  width: 45,
                                  child: Text(
                                    '${standing.points}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 45,
                                  child: Text(
                                    '${standing.played}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                                SizedBox(
                                  width: 45,
                                  child: Text(
                                    '${standing.wins}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 45,
                                  child: Text(
                                    '${standing.draws}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 45,
                                  child: Text(
                                    '${standing.losses}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 45,
                                  child: Text(
                                    '${standing.goalDifference >= 0 ? '+' : ''}${standing.goalDifference}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: standing.goalDifference > 0
                                          ? Colors.green
                                          : standing.goalDifference < 0
                                          ? Colors.red
                                          : Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Container(
                        decoration: BoxDecoration(color: Colors.grey.shade100),
                        padding: const EdgeInsets.all(16.0),
                        child: const Text(
                          'P = Pontos | J = Jogos | V = Vitórias | E = Empates | D = Derrotas | SG = Saldo de Gols',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
