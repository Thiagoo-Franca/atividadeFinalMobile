import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/game.dart';

class Clash extends HookWidget {
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
    final teamAController = useTextEditingController(
      text: game.golsTimeA != null ? game.golsTimeA.toString() : '',
    );
    final teamBController = useTextEditingController(
      text: game.golsTimeB != null ? game.golsTimeB.toString() : '',
    );

    useEffect(() {
      teamAController.text = game.golsTimeA != null
          ? game.golsTimeA.toString()
          : '';
      teamBController.text = game.golsTimeB != null
          ? game.golsTimeB.toString()
          : '';
      return null;
    }, [game.id, game.golsTimeA, game.golsTimeB]);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    teamAName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: teamAController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        hintText: '0',
                      ),
                      onChanged: (value) {
                        game.golsTimeA = value.isEmpty
                            ? null
                            : int.tryParse(value);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'VS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(0, 69, 49, 1),
                ),
              ),
            ),

            Expanded(
              child: Column(
                children: [
                  Text(
                    teamBName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: teamBController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        hintText: '0',
                      ),
                      onChanged: (value) {
                        game.golsTimeB = value.isEmpty
                            ? null
                            : int.tryParse(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
