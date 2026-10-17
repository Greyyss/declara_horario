
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'login_page.dart';
import 'detalle_declaracion_page.dart';

class SuperiorPage extends StatelessWidget {
  const SuperiorPage({super.key});

  // Cierra la sesión del superior.
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

  // Muestra solamente las declaraciones asignadas al superior.
  Widget mostrarDeclaracionesPendientes() {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Center(
        child: Text('Debés iniciar sesión para continuar.'),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('declarations')
          .where('superiorId', isEqualTo: usuario.uid)
          .where(
            'estado',
            isEqualTo: 'PENDIENTE_FIRMA_SUPERIOR',
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error al cargar declaraciones: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final declaraciones = snapshot.data!.docs;

        if (declaraciones.isEmpty) {
          return const Center(
            child: Text(
              'No tenés declaraciones pendientes de revisión.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: declaraciones.length,
          itemBuilder: (context, index) {
            final declaracion = declaraciones[index];
            final datos = declaracion.data();

            final nombre =
                datos['nombreFuncionario'] ?? 'Sin nombre';

            final periodo =
                datos['periodo'] ?? 'Sin período';

            final unidad =
                datos['unidad'] ?? 'Sin unidad';

            final version =
                datos['versionActual'] ?? 1;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.pending_actions,
                          color: Color(0xFF6747A5),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Pendiente de firma del superior',
                            style: TextStyle(
                              color: Color(0xFF6747A5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Text(
                      nombre.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text('Unidad: $unidad'),
                    Text('Período: $periodo'),
                    Text('Versión: $version'),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetalleDeclaracionPage(
                                declaracionId: declaracion.id,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('Revisar declaración'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6747A5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del Superior Jerárquico'),
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
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFFF2ECFA),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Declaraciones pendientes',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6747A5),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Consultá las declaraciones que '
                  'tenés asignadas para revisión.',
                ),
              ],
            ),
          ),
          Expanded(
            child: mostrarDeclaracionesPendientes(),
          ),
        ],
      ),
    );
  }
}


