
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/declaracion_model.dart';
import '../models/nombramiento_model.dart';
import '../models/trabajo_externo_model.dart';

class DeclaracionService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<String> guardarDeclaracion({
    required String nombre,
    required String identificacion,
    required String telefono,
    required String correo,
    required String unidad,
    required String periodo,
    required List<NombramientoModel> nombramientos,
    required List<TrabajoExternoModel> trabajosExternos,
  }) async {
    final usuario = auth.currentUser;

    if (usuario == null) {
      throw Exception('No hay un usuario con sesión iniciada');
    }

    final referencia = firestore.collection('declarations').doc();

    final declaracion = DeclaracionModel(
      id: referencia.id,
      usuarioId: usuario.uid,
      nombreFuncionario: nombre,
      identificacion: identificacion,
      telefono: telefono,
      correo: correo,
      unidad: unidad,
      periodo: periodo,
      estado: 'BORRADOR',
      fechaCreacion: DateTime.now(),
    );

    final batch = firestore.batch();

    batch.set(referencia, {
      ...declaracion.toMap(),
      'id': referencia.id,
    });

    for (final nombramiento in nombramientos) {
      final documento = referencia.collection('appointments').doc();

      batch.set(documento, nombramiento.toMap());
    }

    for (final trabajo in trabajosExternos) {
      final documento = referencia.collection('externalJobs').doc();

      batch.set(documento, trabajo.toMap());
    }

    await batch.commit();

    return referencia.id;
  }
}
