import 'package:flutter/material.dart';
import 'widgets/auth/auth_wrapper.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eFootRounds',
      theme: ThemeData(primarySwatch: Colors.red, useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}
