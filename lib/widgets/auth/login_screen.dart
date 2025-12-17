import 'package:flutter/material.dart';
import 'package:myapp/controllers/auth_controller.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthController>();

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
            Text(
              'Bem-vindo! Por favor, faça login.',
              style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color.fromRGBO(0, 69, 49, 1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onPressed: () async {
                final success = await authProvider.signInWithGoogle();
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(authProvider.error ?? 'Erro desconhecido'),
                    ),
                  );
                }
              },
              icon: Icon(Icons.g_mobiledata, size: 24),
              label: Text('Login com Google'),
            ),
          ],
        ),
      ),
    );
  }
}
