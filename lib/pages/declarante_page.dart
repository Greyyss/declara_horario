
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/websocket_service.dart';
import 'login_page.dart';
import 'declaracion_form_page.dart';
import 'mis_declaraciones_page.dart';

class DeclarantePage extends StatefulWidget {
  const DeclarantePage({super.key});

  @override
  State<DeclarantePage> createState() => _DeclarantePageState();
}

class _DeclarantePageState extends State<DeclarantePage> {
  final WebSocketService webSocketService = WebSocketService();

  bool conectado = false;

  @override
  void initState() {
    super.initState();
    conectarWebSocket();
  }

  void conectarWebSocket() {
    webSocketService.conectar(
      onNotificacion: (titulo, mensaje) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF6747A5),
            duration: const Duration(seconds: 5),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  mensaje,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );

    // La conexión se inicia automáticamente al abrir el panel.
    // El estado real se comprueba al enviar la prueba.
  }

  void probarWebSocket() {
    if (webSocketService.socket?.connected == true) {
      setState(() {
        conectado = true;
      });

      webSocketService.probarNotificacion();
    } else {
      setState(() {
        conectado = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay conexión con el servidor WebSocket.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> cerrarSesion() async {
    webSocketService.desconectar();

    await AuthService().cerrarSesion();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    webSocketService.desconectar();
    super.dispose();
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
            onPressed: cerrarSesion,
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
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

              // BOTÓN PARA PROBAR WEBSOCKET
              SizedBox(
                width: 280,
                child: ElevatedButton.icon(
                  onPressed: probarWebSocket,
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Probar notificación WebSocket'),
                ),
              ),

              const SizedBox(height: 18),

              // BOTÓN NUEVA DECLARACIÓN
              SizedBox(
                width: 280,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const DeclaracionFormPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva declaración'),
                ),
              ),

              const SizedBox(height: 18),

              // BOTÓN MIS DECLARACIONES
              SizedBox(
                width: 280,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const MisDeclaracionesPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Mis declaraciones'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
