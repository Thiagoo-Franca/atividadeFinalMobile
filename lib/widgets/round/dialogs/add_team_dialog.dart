import 'package:flutter/material.dart';

class AddTeamDialog extends StatefulWidget {
  const AddTeamDialog({super.key});

  @override
  State<AddTeamDialog> createState() => _AddTeamDialogState();
}

class _AddTeamDialogState extends State<AddTeamDialog> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      title: const Text('Novo Time'),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nome do time',
            hintText: 'Ex: Time A',
            prefixIcon: Icon(Icons.sports_soccer),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
            hintStyle: TextStyle(color: Color.fromARGB(255, 150, 150, 150)),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,

          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, insira um nome válido.';
            }
            if (value.trim().length < 2) {
              return 'O nome deve ter pelo menos 2 caracteres.';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 237, 255, 243),
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _nameController.text.trim());
            }
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}
