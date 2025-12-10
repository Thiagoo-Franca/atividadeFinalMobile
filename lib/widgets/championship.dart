import 'package:flutter/material.dart';
import 'package:myapp/models/championship.dart';

class Championships extends StatelessWidget {
  final List<Championship> championships;
  final Function(Championship) onTap;

  const Championships({
    super.key,
    required this.championships,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: championships.map((championship) {
        return ListTile(
          title: Text(championship.name),
          onTap: () => onTap(championship),
        );
      }).toList(),
    );
  }
}
