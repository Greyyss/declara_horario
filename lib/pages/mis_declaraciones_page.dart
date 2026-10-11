
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MisDeclaracionesPage extends StatelessWidget {
  const MisDeclaracionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis declaraciones'),
        backgroundColor: Colors.deepPurple,
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

                final declaraciones = snapshot.data!.docs;

                declaraciones.sort((a, b) {
                  final fechaA = a.data()['fechaCreacion'] as Timestamp?;
                  final fechaB = b.data()['fechaCreacion'] as Timestamp?;

                  if (fechaA == null || fechaB == null) return 0;

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
                    final datos = declaraciones[index].data();

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

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(
                          Icons.description,
                          color: Colors.deepPurple,
                        ),
                        title: Text(nombre),
                        subtitle: Text(
                          'Período: $periodo\n'
                          'Fecha: $fechaTexto\n'
                          'Estado: $estado',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
