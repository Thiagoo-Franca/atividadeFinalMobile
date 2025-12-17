import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AddChampionshipDialog extends HookWidget {
  const AddChampionshipDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());

    return AlertDialog(
      title: const Text('Novo Campeonato'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nome do campeonato',
            hintText: 'Ex: Champions League 2025',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.emoji_events),
          ),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor, insira um nome válido.';
            }
            if (value.trim().length < 3) {
              return 'O nome deve ter pelo menos 3 caracteres.';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(0, 69, 49, 1),
          ),
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(context, nameController.text.trim());
            }
          },
          child: const Text('Criar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
