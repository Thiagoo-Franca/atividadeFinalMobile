import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/providers.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authController = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 69, 49, 1),
      appBar: AppBar(
        toolbarHeight: 350,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/Efoot.png', height: 130),
            Image.asset('assets/images/Rounds.png', height: 130),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bem-vindo! Por favor, faça login.',
              style: TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            ListenableBuilder(
              listenable: authController,
              builder: (context, _) {
                return ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color.fromRGBO(0, 69, 49, 1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: authController.isLoading
                      ? null
                      : () async {
                          final success = await authController
                              .signInWithGoogle();
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  authController.error ?? 'Erro ao fazer login',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  icon: authController.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color.fromRGBO(0, 69, 49, 1),
                          ),
                        )
                      : const Icon(Icons.g_mobiledata, size: 28),
                  label: Text(
                    authController.isLoading
                        ? 'Entrando...'
                        : 'Login com Google',
                    style: const TextStyle(fontSize: 16),
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
