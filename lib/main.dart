
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const DeclaraHorarioApp());
}

class DeclaraHorarioApp extends StatelessWidget {
  const DeclaraHorarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeclaraHorario',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6747A5),
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
