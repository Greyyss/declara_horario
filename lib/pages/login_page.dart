
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'declarante_page.dart';
import 'superior_page.dart';
import 'rrhh_page.dart';
import 'admin_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final correoController = TextEditingController();
  final contrasenaController = TextEditingController();
  final AuthService authService = AuthService();

  bool cargando = false;
  bool mostrarContrasena = false;

  Future<void> iniciarSesion() async {
    String correo = correoController.text.trim();
    String contrasena = contrasenaController.text;

    if (correo.isEmpty || contrasena.isEmpty) {
      mostrarMensaje('Ingresá tu correo y contraseña.');
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      User? usuario = await authService.iniciarSesion(
        correo,
        contrasena,
      );

      if (usuario != null) {
        Map<String, dynamic>? datos =
            await authService.obtenerDatosUsuario(usuario.uid);

        if (!mounted) return;

        if (datos == null) {
          await authService.cerrarSesion();

          if (!mounted) return;

          mostrarMensaje(
            'Este usuario no tiene un perfil registrado.',
          );
          return;
        }

        String rol = datos['rol'] ?? '';

        // Abrir el panel correspondiente según el rol
        if (rol == 'declarante') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DeclarantePage(),
            ),
          );
        } else if (rol == 'superior') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SuperiorPage(),
            ),
          );
        } else if (rol == 'rrhh') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const RrhhPage(),
            ),
          );
        } else if (rol == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminPage(),
            ),
          );
        } else {
          await authService.cerrarSesion();

          if (!mounted) return;

          mostrarMensaje(
            'El usuario no tiene un rol válido: $rol',
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        mostrarMensaje('Correo o contraseña incorrectos.');
      } else {
        mostrarMensaje(
          'Error al iniciar sesión: ${e.message}',
        );
      }
    } catch (e) {
      if (!mounted) return;

      mostrarMensaje(
        'Ocurrió un error al consultar el usuario.',
      );
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  @override
  void dispose() {
    correoController.dispose();
    contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 5,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.assignment_turned_in,
                      size: 65,
                      color: Color(0xFF6747A5),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      'DeclaraHorario',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF44316C),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Sistema de Declaración de Horarios',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Campo de correo electrónico
                    TextField(
                      controller: correoController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Campo de contraseña
                    TextField(
                      controller: contrasenaController,
                      obscureText: !mostrarContrasena,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              mostrarContrasena = !mostrarContrasena;
                            });
                          },
                          icon: Icon(
                            mostrarContrasena
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      onSubmitted: (_) {
                        if (!cargando) {
                          iniciarSesion();
                        }
                      },
                    ),

                    const SizedBox(height: 25),

                    // Botón para iniciar sesión
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: cargando ? null : iniciarSesion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6747A5),
                          foregroundColor: Colors.white,
                        ),
                        child: cargando
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Iniciar sesión'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
