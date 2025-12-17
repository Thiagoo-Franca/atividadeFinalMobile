import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game.dart';

class Clash extends StatefulWidget {
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
  State<Clash> createState() => _ClashState();
}

class _ClashState extends State<Clash> {
  late TextEditingController _teamAController;
  late TextEditingController _teamBController;

  @override
  void initState() {
    super.initState();
    // Inicializa com valor vazio se for null, senão com o valor atual
    _teamAController = TextEditingController(
      text: widget.game.golsTimeA != null
          ? widget.game.golsTimeA.toString()
          : '',
    );
    _teamBController = TextEditingController(
      text: widget.game.golsTimeB != null
          ? widget.game.golsTimeB.toString()
          : '',
    );
  }

  @override
  void didUpdateWidget(Clash oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Atualiza os controllers se o game mudou
    if (oldWidget.game.id != widget.game.id) {
      _teamAController.text = widget.game.golsTimeA != null
          ? widget.game.golsTimeA.toString()
          : '';
      _teamBController.text = widget.game.golsTimeB != null
          ? widget.game.golsTimeB.toString()
          : '';
    }
  }

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Time A
            Expanded(
              child: Column(
                children: [
                  Text(
                    widget.teamAName,
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
                      controller: _teamAController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        hintText: '0',
                      ),
                      onChanged: (value) {
                        // Atualiza o score no modelo
                        widget.game.golsTimeA = value.isEmpty
                            ? null
                            : int.tryParse(value);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // VS
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

            // Time B
            Expanded(
              child: Column(
                children: [
                  Text(
                    widget.teamBName,
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
                      controller: _teamBController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        hintText: '0',
                      ),
                      onChanged: (value) {
                        // Atualiza o score no modelo
                        widget.game.golsTimeB = value.isEmpty
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
