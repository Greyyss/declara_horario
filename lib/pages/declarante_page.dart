
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class DeclarantePage extends StatelessWidget {
  const DeclarantePage({super.key});

  Future<void> cerrarSesion(BuildContext context) async {
    await AuthService().cerrarSesion();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Declarante'),
        backgroundColor: const Color(0xFF6747A5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => cerrarSesion(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.assignment_turned_in,
                size: 80,
                color: Color(0xFF6747A5),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bienvenido a DeclaraHorario',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Desde aquí podrás gestionar tus declaraciones de horario.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.add),
                label: const Text('Nueva declaración'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
