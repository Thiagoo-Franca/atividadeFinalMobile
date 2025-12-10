import 'package:flutter/material.dart';
import 'package:myapp/models/game.dart';
import 'package:myapp/providers/game_provider.dart';
import 'package:provider/provider.dart';

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
