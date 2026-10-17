
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'detalle_declaracion_page.dart';

class MisDeclaracionesPage extends StatelessWidget {
  const MisDeclaracionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis declaraciones'),
        backgroundColor: const Color(0xFF6747A5),
        foregroundColor: Colors.white,
      ),
      body: usuario == null
          ? const Center(
              child: Text('No hay una sesión iniciada'),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('declarations')
                  .where('usuarioId', isEqualTo: usuario.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar declaraciones: ${snapshot.error}',
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final declaraciones = snapshot.data!.docs.toList();

                // Ordenar las declaraciones de la más reciente
                // a la más antigua.
                declaraciones.sort((a, b) {
                  final fechaA =
                      a.data()['fechaCreacion'] as Timestamp?;
                  final fechaB =
                      b.data()['fechaCreacion'] as Timestamp?;

                  if (fechaA == null || fechaB == null) {
                    return 0;
                  }

                  return fechaB.compareTo(fechaA);
                });

                if (declaraciones.isEmpty) {
                  return const Center(
                    child: Text(
                      'Todavía no tenés declaraciones guardadas.',
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

                    final estado =
                        datos['estado'] ?? 'BORRADOR';

                    final fecha =
                        datos['fechaCreacion'] as Timestamp?;

                    final fechaTexto = fecha == null
                        ? 'Sin fecha'
                        : '${fecha.toDate().day}/'
                          '${fecha.toDate().month}/'
                          '${fecha.toDate().year}';

                    // Color según el estado de la declaración.
                    Color colorEstado = Colors.grey;

                    if (estado == 'BORRADOR') {
                      colorEstado = Colors.orange;
                    } else if (estado == 'ENVIADA') {
                      colorEstado = Colors.blue;
                    } else if (estado == 'APROBADA') {
                      colorEstado = Colors.green;
                    } else if (estado == 'RECHAZADA') {
                      colorEstado = Colors.red;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.description,
                                  color: Color(0xFF6747A5),
                                  size: 30,
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Text(
                                    nombre.toString(),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Text('Período: $periodo'),
                            Text('Fecha: $fechaTexto'),

                            const SizedBox(height: 10),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colorEstado.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                estado.toString(),
                                style: TextStyle(
                                  color: colorEstado,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

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
                                icon: const Icon(
                                  Icons.visibility,
                                ),
                                label: const Text(
                                  'Ver detalle',
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
            ),
    );
  }
}
